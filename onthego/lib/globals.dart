import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_class.dart';

LocationData currentLocation;

bool firstOpen = true;
bool favouritesChanged = true;

List<String> currentFavourites = [];

Stop currentStopNearby;
List<Stop> currentNearbyStops;
List<ArrivalTime> currentArrivalTimesNearby;

Stop currentStopFavourites;
List currentFavouriteStops;
List currentArrivalTimesFavourites;

const ANIMATION_DURATION = 300;

const FAVOURITES_ID_LIST_KEY = "57";

const BOTTOM_NAVIGATION_BAR_HEIGHT = 60.0;
const TOGGLE_BAR_HEIGHT = 0.06;
const TOGGLE_HEIGHT = TOGGLE_BAR_HEIGHT * 0.8;
const TOGGLE_WIDTH = 0.5;
const PULL_TAB_HEIGHT = 0.03;

const LIST_VIEW_TITLE_BAR_HEIGHT = 0.22;
const LIST_VIEW_ITEM_HEIGHT = 0.13;
const LIST_VIEW_TITLE_BAR_TEXT_SIZE = 0.025;
const LIST_VIEW_ITEM_TEXT_SIZE = 0.0205;

const LIST_VIEW_TITLE_BAR_HEIGHT_FAVOURITES = 0.15;

const INITIAL_MAP_HEIGHT = 200.0;
const MAX_MAP_HEIGHT = 500.0;

final Location location = new Location();

readFavourites() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getStringList(FAVOURITES_ID_LIST_KEY) ?? [];
  currentFavourites = value;
}

writeFavourites() async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setStringList(FAVOURITES_ID_LIST_KEY, currentFavourites);
  favouritesChanged = true;
}