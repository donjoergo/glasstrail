# general

The app is called "Glass Trail" (technically GlassTrail) in which someone can track their drink consumption.
drinks can be anything non alcoholic e.g. water, juice, energy drinks or alcoholic e.g. beer, wine, spirits, cocktails, etc.

## Techstack

Frontend: Flutter
Backend: you can decide freely, provide options

## Design

The app should have a modern Material design.
It should support dark and light mode and automatic switching.
Provide me with a color palette and branding for the app.
languages should be english and german supported.
The app should be mobile first, but desktop should also be considered.


the app should be multi tenant. each user should have their own data.
users can have friends. they can send friend requests to other users. if the request is accepted, they are friends.

the main functionality is to log drinks and see the consumption. each time the user logs a drink, all his friends should get notified and see it in their feed.

# App structure

- Feed
- Map
- Plus button (add drink)
- Statistics
- Profile (settings, friends, etc.)

## Floating action button

a floating action button should be visible on all screens except the add drink screen. it should be used to add a new drink.

## Feed

Show a list of drinks logged by the user and his friends.
Posts can be liked (cheered) and commented on.
also achieved achievements should be shown in the feed. multiple achieved achievements should be condensed into one entry.

## Map

The map should show currentyl consumed drinks. After a certain amount of time the drink should fade out and disappear.
Show a map with the user's current location.
When the user logs a drink, the drink should be shown on the map at the user's location.
When friends log a drink, the drink should be shown on the map at the friend's location.

## Plus button (add drink)

here a new drink can be added.

1. choose a drink from the drink list
   1. make the selection somewhat easy
   2. show the most recent drinks first
   3. group drinks by category
2. choose a photo of the drink (optional)
3. choose a text field to add a comment (optional)
4. choose if friends should be notified (default: true)
5. big button to confirm the entry

## Statistics

Show statistics about the user's drink consumption.

### Statistics Overview

show an overview of the user's drink consumption.
show a wwekly total, monthly total, yearly total.
show a current streak and best streak.
show a pie chart of the user's drink consumption by category.

### Statistics Map

show a map with all the drinks the user has logged.

### Statistics List

show a list of all the drinks the user has logged.
show all drinks in total and per category.
show current and best streak of days the user has logged a drink.



## Profile (settings, friends, etc.)

Show the user's profile (name, picture). here the user can also edit his profile (display name, profile picture, birthday)
all the achievements the user has earned should also be displayed here. it must be possible to see which achievements are earned and which are not. it must be possible to see the details of each achievement.
Show the user's friends.
Show the user's settings.
log out.

# Settings
change the apps theme (auto/light/dark).
change the app language (english/german).
change units (ml/oz).
import data from BeeerWithMe, see chapter below.


## import function

in settings also an import function is available.
it should be possible to import the data from the BeeerWithMe app. An example json file is is provided in resources.
the file should be validated and the user should be informed about any errors.
there are different glasstypes in the json file. these should be mapped to the default glasstypes in the app.


# global drink list

There should be a global list of drinks that can be used by all users.

- Beer
  - Pils
  - Helles
  - Weizen
  - Kellerbier
  - Kölsch
  - Alt
  - IPA
  - etc.
- Wine
  - Red wine
  - White wine
  - Rosé wine
  - Sparkling wine
  - Aperol Spritz
  - etc.
- Spirits
  - Vodka
  - Gin
  - Rum
  - Whiskey
  - Tequila
  - etc.
- Cocktails
  - Mojito
  - Margarita
  - Martini
  - etc.
- Non alcoholic drinks
  - Water
  - Juice
  - Sparkling water
  - Tea
  - Coffee
  - Energy drinks
  - Soft drinks
    - Cola
    - Lemonade
    - etc.

the user should be able to add new drinks to his own drink list or edit existing drinks.

each drink should have a name (mandatory), a category (mandatory), an image (optional), a volume (optional).


# Gamification

whenever the user logs a drink, the app should check if the user has earned any achievements.
if so, the user should be notified and the achievement should be displayed in the profile. also a nice animation should be shown.

think of cool names for the different categories and levels.

below are some examples of possible achievements.

User can earn achievements for logging drinks.

- first drink
- 10 drinks
- 50 drinks
- 100 drinks
- 200 drinks
- 500 drinks
- 1000 drinks
- etc.

User can earn achievements for logging drinks with friends.

- first drink with a friend
- 10 drinks with a friend
- 20 drinks with a friend
- 50 drinks with a friend
- 100 drinks with a friend
- 200 drinks with a friend
- 500 drinks with a friend
- etc.

User can earn achievements for logging drinks on special occasions.

- birthday
- anniversary
- christmas
- easter
- new year
- st. patrick's day
- oktoberfest
- carnival
- halloween
- etc.

user can earn achievements for logging different types of drinks.

- 10 beer (beer connoisseur)
- 10 wine (wine connoisseur)
- 10 spirits (spirits connoisseur)
- 10 cocktails (cocktail connoisseur)
- 10 non alcoholic drinks (non alcoholic connoisseur)
- etc.

streaks:

- 3 days
- 7 days
- 14 days
- 30 days
- 60 days
- 90 days
- 180 days
- 365 days
- etc.



# Notifications

User should get notifications when:

- a friend logs a drink (most important)
- it's a special occasion (birthday, anniversary, etc.)
- a friend sends a friend request
- a friend accepts a friend request
- a friend rejects a friend request
- a friend invites a friend

# onboarding journey

via an invite link the user should be able to create an account and join the app.

1. enter E-Mail and password.
2. ask about a nickname, a display name and a profile picture (optional).
3. Optional ask for birthday. if provided, the user will get a achievements for his birthday.
4. ask if data from the BeerWithMe app should be imported.

# Provide Feedback

User can report issues and provide feedback or suggest new features.
They can also suggest new drinks to be added to the global drink list.
