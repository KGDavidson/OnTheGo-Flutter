import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:location/location.dart';
import 'global_class.dart';

LocationData currentLocation;
MapController mapController = MapController();

String currentSearchString = "";

bool firstOpen = true;
bool favouritesChanged = false;
bool loadingNearby = true;
bool loadingFavourites = true;
bool showSearchInput = false;

int selectedToggle = 0;

Map<String, dynamic> currentFavourites = {};

Stop currentStopNearby;
List<Stop> currentNearbyStops;
List<ArrivalTime> currentArrivalTimesNearby;

Stop currentStopFavourites;
List currentFavouriteStops;
List currentArrivalTimesFavourites;

const ANIMATION_DURATION = 300;
const SEARCH_RADIUS = 1500;

const FAVOURITES_ID_LIST_KEY = "favourites";

const BOTTOM_NAVIGATION_BAR_HEIGHT = 60.0;
const TOGGLE_BAR_HEIGHT = 0.06;
const TOGGLE_HEIGHT = TOGGLE_BAR_HEIGHT * 0.8;
const TOGGLE_WIDTH = 0.5;
const PULL_TAB_HEIGHT = 0.03;

const LIST_VIEW_TITLE_BAR_HEIGHT = 0.22;
const LIST_VIEW_ITEM_HEIGHT = 0.13;
const LIST_VIEW_TITLE_BAR_TEXT_SIZE = 0.021;
const LIST_VIEW_ITEM_TEXT_SIZE = 0.019;

const LIST_VIEW_TITLE_BAR_HEIGHT_FAVOURITES = 0.15;

const LIST_VIEW_TITLE_MAX_LENGTH = 21;

const INITIAL_MAP_HEIGHT = 150.0;
final double MAX_MAP_HEIGHT = window.physicalSize.width / window.devicePixelRatio;

final Location location = new Location();
