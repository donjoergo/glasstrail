# Achievement Reminder Push Copy

This document locks the v1 reminder-push titles and bodies.

## Copy Rules

- Each reminder push uses an event-style title, not the badge title.
- The body is short, direct, and action-oriented.
- Copy assumes the push opens the achievement detail first, not the add-drink flow.
- There is no combined multi-reminder push in v1.
- Reminders only exist for reminder-based occasion badges.

## Key Pattern

- title: `achievementReminder<Stem>Title`
- body: `achievementReminder<Stem>Body`

Stems:

- `Birthday`
- `FirstSipAnniversary`
- `NewYear`
- `Christmas`
- `Easter`
- `Halloween`
- `StPatricksDay`
- `Oktoberfest`
- `Carnival`

## Exact Copy

### Birthday

- `achievementReminderBirthdayTitle`
  - `Happy birthday! 🎉`
  - `Alles Gute zum Geburtstag! 🎉`
- `achievementReminderBirthdayBody`
  - `Log a drink today to earn your birthday badge.`
  - `Logge heute ein Getränk, um dein Geburtstags-Badge zu verdienen.`

### First Sip Anniversary

- `achievementReminderFirstSipAnniversaryTitle`
  - `{years} years of drinks logged 🥂`
  - `{years} Jahre Getränke erfasst 🥂`
- `achievementReminderFirstSipAnniversaryBody`
  - `Log a drink today to earn your anniversary badge.`
  - `Logge heute ein Getränk, um dein Jubiläums-Badge zu verdienen.`

### New Year

- `achievementReminderNewYearTitle`
  - `Happy New Year! 🥂`
  - `Frohes neues Jahr! 🥂`
- `achievementReminderNewYearBody`
  - `Log a drink today to earn your New Year badge.`
  - `Logge heute ein Getränk, um dein Neujahrs-Badge zu verdienen.`

### Christmas

- `achievementReminderChristmasTitle`
  - `Merry Christmas! 🎄`
  - `Frohe Weihnachten! 🎄`
- `achievementReminderChristmasBody`
  - `Log a drink today to earn your Christmas badge.`
  - `Logge heute ein Getränk, um dein Weihnachts-Badge zu verdienen.`

### Easter

- `achievementReminderEasterTitle`
  - `Happy Easter! 🐣`
  - `Frohe Ostern! 🐣`
- `achievementReminderEasterBody`
  - `Log a drink this Easter weekend to earn this badge.`
  - `Logge an diesem Osterwochenende ein Getränk, um dieses Badge zu verdienen.`

### Halloween

- `achievementReminderHalloweenTitle`
  - `It's Halloween! 🎃`
  - `Es ist Halloween! 🎃`
- `achievementReminderHalloweenBody`
  - `Log a drink today to earn your Halloween badge.`
  - `Logge heute ein Getränk, um dein Halloween-Badge zu verdienen.`

### St. Patrick's Day

- `achievementReminderStPatricksDayTitle`
  - `It's St. Patrick's Day! 🍀`
  - `Heute ist St. Patrick's Day! 🍀`
- `achievementReminderStPatricksDayBody`
  - `Log a beer today to earn your St. Patrick's Day badge.`
  - `Logge heute ein Bier, um dein St.-Patrick's-Day-Badge zu verdienen.`

### Oktoberfest

- `achievementReminderOktoberfestTitle`
  - `Oktoberfest is on! 🍺`
  - `Oktoberfest läuft! 🍺`
- `achievementReminderOktoberfestBody`
  - `Log a beer during Oktoberfest to earn this badge.`
  - `Logge während des Oktoberfests ein Bier, um dieses Badge zu verdienen.`

### Carnival

- `achievementReminderCarnivalTitle`
  - `Carnival is on! 🎊`
  - `Karneval läuft! 🎊`
- `achievementReminderCarnivalBody`
  - `Log a drink during Carnival to earn this badge.`
  - `Logge während des Karnevals ein Getränk, um dieses Badge zu verdienen.`

## Fallback Copy

Keep a generic fallback in case the payload references an unknown reminder family:

- `achievementReminderGenericTitle`
  - `Achievement reminder`
  - `Achievement-Erinnerung`
- `achievementReminderGenericBody`
  - `Open GlassTrail to check today's achievement.`
  - `Öffne GlassTrail, um dir das heutige Achievement anzusehen.`

## Notes

- Birthday and anniversary reminders can validly fire on the same day the prerequisite becomes known, as long as the device becomes eligible before the local `23:00` cutoff.
- Anniversary reminder titles use the anniversary of the earliest-known drink entry, including BeerWithMe imports, so they must not call it a GlassTrail account anniversary.
- `years` is a localized integer placeholder. Use singular forms for year 1 in implementation if the localization layer supports it.
- If a user already earned the badge on another device before opening the push, the same title/body can still be shown; the app will simply open the earned detail state.
