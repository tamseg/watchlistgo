# Watchlist Go - TODO List

## 1. Search functionality

- [ ] **Search UI**: Create the UI for the Search page.
- [ ] **Search Algorithm**: Implement searching via the TMDB API for both movies and series.
- [ ] **Search Result Cards**: Display results as cards (similar to the home screen).
- [ ] **Add to List**: Instead of a 3-dots menu, search result cards should have a `+ Add` button.
- [ ] **Routing Logic**: Clicking `+ Add` should determine whether the item is a movie or a series and add it to the relevant tab/list in the user's Watchlist safely.

## 2. Profile & Settings

- [ ] **Profile UI**: Build the settings interface.
- [ ] **Theme Settings**: Add an option to switch themes. Default is "System Default", with options for explicitly forcing "Light" or "Dark" mode.
- [ ] **Default Tab Preference**: Allow the user to select whether "Series" (default) or "Movies" is the initial tab opened on the Home screen.
- [ ] **Auth Actions**: Add placeholder options for "Log Out" and "Delete Account" buttons (to be functional after auth is implemented).

## 3. Card Interactions (Home Screen)

- [ ] **Card Options Menu**: Hook up the 3-dots menu on `MovieCard` and `SeriesCard`.
- [ ] **Remove**: Add the ability to remove an item from the watchlist.
- [ ] **Reorder/Move**: Add the ability to manually sort or move the card's position in the list.

## 4. Theme & Styling

- [ ] **Color Schemes**: Think of and implement complete, cohesive color palettes for both the Light and Dark themes.
- [ ] **Fonts/Typography**: Explore and integrate custom fonts to polish the app's look and feel.

## 5. Account & Backend

- [ ] **Authentication**: Implement Sign Up and Sign In functionality.
- [ ] **Database Integration**: Research and connect accounts to a free Backend-as-a-Service (e.g., Firebase, Supabase, or Appwrite) to save user data so the watchlist is continuously synced and accessible across multiple devices.

## Future Polish

- [ ] Re-evaluate the `ScrollingText` long-press interaction approach if it proves inconvenient on actual physical devices during broader testing.
