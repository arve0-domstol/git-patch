# git-patch

`git-patch` gjør det mulig å teste en feature-branch sammen med mindre endringer
som ligger i andre brancher, uten å blande arbeidsområdene permanent.

En patch er en selvstendig endring fra en annen branch. Patchen kan være under
godkjenning og bli tilgjengelig på `main` mens feature-arbeidet pågår. Da kan
`git-patch` fjerne patchen fra feature-branchen og rebase feature-arbeidet på
den oppdaterte `main`.

## Installere
Gitt at du har ~/bin i PATH:

```shell
# lenke
ln -s $(pwd)/git-patch ~/bin/git-patch

# eller kopiere
cp git-patch ~/bin/git-patch
```


## Kommandoer

```shell
# se alle kommandoer
git patch help

# Legg til den totale diffen fra cache
git patch add cache

# Vis aktive patcher og om de trenger oppdatering
git patch list

# Oppdater bare cache fra branchens nåværende totale diff
git patch sync cache

# Oppdater alle patcher, rydd leverte patcher og oppdater fra main
git patch sync

# Sjekk om cache kan legges til uten konflikter
# Kan også brukes etter at cache er lagt til,
# for å finne ut om det er konflikter mellom
# vårt arbeid og patch-branchen
git patch check-conflicts cache

# Fjern en bestemt patch
git patch drop cache

# Fjern alle patcher
git patch drop

# Vis historikken for stacken
git patch log

# Publiser patcher og feature-arbeid som en stacked PR
git patch publish-stacked
```

### `add <patch>`

`add` lagrer en snapshot av patchens totale diff og legger den inn under eget
arbeid på feature-branchen. Navnet på patchen er branch-navnet.

Den lokale branchen brukes. Verktøyet henter samtidig fra remote og varsler hvis
`origin/<patch>` er nyere:

```text
origin/cache er nyere enn lokal cache
Lokal cache ble lagt til. Oppdater den lokale cache-branchen og kjør
`git patch sync cache` hvis remote-versjonen skal brukes.
```

Patchen skal kunne legges til uavhengig av andre aktive patcher. Hvis den
avhenger av dem, stopper kommandoen med en forklaring. Det samme gjelder
konflikter og merge-commits i patchen.

### `sync <patch>`

`sync cache` sammenligner den aktive `cache`-patchen med den nåværende totale
diffen på branch `cache`.

Hele patchen erstattes:

- nye filer og linjer legges til;
- fjernede filer og linjer forsvinner;
- commits som er omskrevet eller flyttet har ingen egen betydning;
- andre aktive patcher og main-basen oppdateres ikke.

Hvis `origin/cache` er nyere enn lokal `cache`, varsles brukeren. Kommandoen
bruker fortsatt den lokale branchen; source må oppdateres lokalt før en ny
sync dersom remote-versjonen ønskes.

### `sync`

`sync` uten argument gjør en full oppdatering:

1. henter oppdatert `main`-referanse via `origin/HEAD`;
2. oppdaterer alle aktive patcher fra sine source-branchen;
3. identifiserer patcher som allerede er kommet inn i `main`;
4. ber om bekreftelse dersom det kun delvis eller endret innhold ser levert ut;
5. bygger historikken på nytt som:

   ```text
   oppdatert main -> gjenværende patcher -> eget arbeid
   ```

Operasjonen er basert på endringer, ikke på commit-rekkefølge. Det gjør at
squash, reword eller en reorganisert patch-branch kan håndteres ut fra den totale
diffen.

En patch anses som levert når Git kan finne igjen den originale eller tilsvarende
endringen gjennom ancestry eller `patch-id`. Dersom bare deler av patchen ser
levert ut, eller innholdet er endret på `main`, fjernes den ikke automatisk.
Brukeren får se tvilen og må bekrefte hva som skal gjøres.

### `drop`

`drop cache` fjerner cache-diffen fra feature-branchen og beholder:

```text
oppdatert main -> andre patcher -> eget arbeid
```

`drop` uten argument fjerner alle patcher.

Før en patch fjernes, sjekkes det om feature-arbeidet fortsetter å gjelde med
den fjernede patchen. En konflikt stopper operasjonen og blir vist før noe
endelig endres.

### `list` og `log`

`list` viser minst:

- patch-navn og source-branch;
- rekkefølge i stacken;
- om source-branchen har nye endringer;
- om patchen ser levert ut;
- kjente konflikter.

`log` viser lokale stack-operasjoner, for eksempel:

```text
added cache from 8ca31df
synced logging from c7efb20
dropped cache because its change was found in main
rolled back sync after conflicts
```

## Modell

Patchen er den **samlede diffen** mellom en patch-branch og merge-base med
`origin/HEAD`. Commitrekkefølgen eller antall commits i patch-branchen spiller
ingen rolle.

For eksempel vil dette:

```text
main
  \
   cache: A -- B -- C
feature:           A' -- B' -- egen-endring
```

bli behandlet som om `cache` er én endring, pluss feature-branchens egne
endringer.

En aktiv stack er alltid lineær:

```text
oppdatert main -> patcher -> eget arbeid
```

Avgrensninger:

- patcher kan ikke bygge på hverandre;
- patch-brancher med merge-commits støttes ikke;
- én arbeidsbranch har én lokal patch-stack;
- stack-metadata lagres lokalt i Git og deles mellom worktrees i samme klone;
- en annen klone må opprette sin egen stack igjen.


## Konflikter og sikkerhet

Før en muterende kommando kjøres, sjekkes den aktuelle operasjonen i en
arbeidskopi som ikke endrer feature-branchen.

`git patch check-conflicts cache` kan brukes både før og etter `add`. Ved
konflikt vises hvilke filer og hvilke deler av patchen som kolliderer. Ingen
endringer blir skrevet til feature-branchen.

Muterende kommandoer lagrer ucommittede endringer automatisk med en stash. Hvis
stashen ikke kan legges tilbake etter en konflikt:

1. hele stack-operasjonen rulles tilbake;
2. den opprinnelige branch-spissen gjenopprettes;
3. brukerens endringer beholdes trygt i stash;
4. feilmeldingen forklarer konflikten og foreslår hvordan den kan løses.

Eksempel:

```text
Kan ikke legge til patchen cache på grunn av konflikter:
  src/cache.ts
  src/app.ts

Ingen endringer ble gjort i feature-branchen.
Dine ucommittede endringer ligger i stash@{0}.
Løs patchens konflikt på cache og prøv `git patch add cache` på nytt.
```

Etter konfliktbehandling skal forrige stack-tilstand kunne gjenopprettes uten å
miste commits eller uncommitted work.

## Eksempel: patcher under godkjenning

Branchen `feature` utgår fra `main` og skal testes sammen med `cache` og
`logging`:

```text
origin/main:   A --- B
cache:         B --- C --- D
logging:       B --- E
feature:       B --- F --- G
```

Legg inn patchene:

```shell
git patch add cache
git patch add logging
```

Feature-branchen blir byggd lineært:

```text
B --- cache(CD) --- logging(E) --- feature(FG)
```

`cache` endres til `B --- C --- D2` mens den er under review. Oppdater bare den
patchen:

```shell
git patch sync cache
```

Resultatet blir:

```text
B --- cache(CD2) --- logging(E) --- feature(FG)
```

Senere lander `cache` på `main`, og `main` får enda et eget arbeid:

```text
main: B --- H --- squash(cache)
```

Kjør full sync:

```shell
git patch sync
```

`cache` finnes nå i `main` og fjernes fra stacken. Historikken blir:

```text
main(BHcache) --- logging(E) --- feature(FG)
```

## Publisere som stacked PR

Lokal testing trenger ikke `gh`, men `git patch publish-stacked` krever:

- GitHub CLI (`gh`);
- `gh-stack`-utvidelsen;
- autentisert GitHub-tilgang;
- en repositorykonfigurasjon der stacked PR-er er tilgjengelige.

`git patch publish-stacked` mapper den lokale stacken til en `gh stack`:

```text
(main) <- cache <- logging <- feature
```

Hver aktive patch blir ett lag. Alt arbeid som ikke tilhører en patch blir
samlet i feature-laget øverst i stacken. Eksisterende branch-navn beholdes, og en
åpen PR for patch-branchen gjenbrukes der det er mulig.

Publisering oppretter eller oppdaterer hver branch i riktig base-rekkefølge.
Nye PR-er opprettes som drafts. Senere endringer bruker `--force-with-lease` og
oppdaterer avhengige branches, slik at hvert PR-lag viser bare sin egen diff.
Patch- og feature-branchene bygges først som en ny lineær historie. Branch-navn
beholdes, og feature-treet må være identisk med arbeidsbranchen før den lokale
publiseringshistorikken erstatter eksisterende refs. En patch-source som har
endret seg siden `add` eller `sync` må synkroniseres før publisering.

Brancher, stack-metadata og lokal `gh stack`-sporing oppdateres som én
publiseringstransaksjon. Ved feil i `init` eller `submit` gjenopprettes de
opprinnelige refsene og den eksakte tidligere lokale `gh stack`-tilstanden.

## Under panseret

Lokal stack-behandling bygges rundt Git sine commits, patcher og refs. Konseptet
bruken bygger på, er:

```shell
git cherry-pick
git rebase --onto
```

Patch-metadata lagres som lokale Git-refs/config og gjør det mulig å bygge
stacken på nytt, rulle tilbake og finne igjen hvilke endringer som tilhører
hver patch. Brukeren behøver ikke håndtere denne metadataen manuelt.

GitHub-publisering delegeres til `gh stack` fremfor å simulere en stack med en
egen PR-logikk.

## Utvikling

Kjør hele testsuiten fra rotmappen i repoet:

```shell
./tests/run
```

Hver test oppretter et midlertidig Git-repo med `mktemp -d` og bruker
uavhengige fixtures fra `tests/fixtures/`.