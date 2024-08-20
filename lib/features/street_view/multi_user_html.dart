import 'package:flutter/material.dart';

import '../../config/app_config.dart';

///for showing multiple users on map and on tap of marker show user info page and street view
class MultiUser {
  static String nearByAllUserPage({
    final users,
    final currentAddressName,
    @required var currentUserLocation,
  }) =>
      '''
 <!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Overlays Within Street View</title>
    <script src="https://polyfill.io/v3/polyfill.min.js?features=default"></script>
    <!-- jsFiddle will insert css and js -->
    <style>
        /* Always set the map height explicitly to define the size of the div
       * element that contains the map. */
        #map {
            height: 100%;
        }
#map div.poi-info-window .view-link {
       display:none;
}
        /* Optional: Makes the sample page fill the window. */
        html,
        body {
            height: 100%;
            margin: 0;
            padding: 0;
        }

    img[src*="#custom_marker"] {
    border: 2px solid #FF3A5A !important;
    border-radius: 50%;
    box-sizing:border-box 
}


       
    </style>
</head>

<body>
   
    <div id="map"></div>

    <!-- Async script executes immediately and must be after any DOM elements used in callback. -->
    <script
        src="https://maps.googleapis.com/maps/api/js?key=$googleMapsKey&callback=initMap&v=weekly&channel=2"
        async></script>
</body>

<script>
    
    let panorama;
var currentUserDetails =
  JSON.parse(JSON.stringify($currentUserLocation));
let currentInfoWindow = null;

    function initMap() {
                  // Sample user markers data                                                                            
              var userMarkers1 =
  JSON.parse(JSON.stringify($users));

            // Set the center to the lat/lng of a specific user marker
            const centerUser = userMarkers1[0]; // Change this index as needed
            const centerLatLng = new google.maps.LatLng(centerUser[0].lat, centerUser[0].lng);
        // Set up the map
        const map = new google.maps.Map(document.getElementById("map"), {
            center: centerLatLng??{ lat: 30, lng: 31 },
            zoom:centerLatLng!=null? 14: 2,
            streetViewControl: true,
            zoomControl: false,
              mapTypeControl: false, // Disable map type selection
              fullscreenControl: false, // Disable fullscreen control
              rotateControl: false, // Disable rotate control
              scaleControl: false, // Disable scale control
              panControl: false, 
            streetViewControlOptions: {
   position: google.maps.ControlPosition.TOP_RIGHT,
   
} 
        });


      //Current user marker 
         var markerImage = {
    url: "https://i.ibb.co/Yk1t0xv/3603850.png",
    scaledSize: new google.maps.Size(65, 65), // scaled size
     origin: new google.maps.Point(0, 0),
    anchor: new google.maps.Point(27.5, 27.5),
  };
  const currentLocMarker = new google.maps.Marker({
    position: currentUserDetails,
    map,
    title: "You",
    //  label: "You",
    icon:markerImage,
  });

   // Create an info window for the current user marker.
  const currentInfoWindow1 = new google.maps.InfoWindow({
    content: "<strong>$currentAddressName</strong> is your location.",
  });

  // Add a click listener to the current user marker.
  currentLocMarker.addListener("click", () => {
     if (currentInfoWindow) {
        currentInfoWindow.close();
    }
    // Open the info window for the current user marker.

    currentInfoWindow1.open(map, currentLocMarker);
    currentInfoWindow = currentInfoWindow1;
  });


  // Create an info window to share between markers.
  // const infoWindow = new google.maps.InfoWindow();
    // Create the markers.
    var userMarkers =
  JSON.parse(JSON.stringify($users));
     const markersArray = [];
  userMarkers.forEach(([position, title, icon, id], i) => {
    const image = {
    url:icon !== "https://i.ibb.co/Yk1t0xv/3603850.png" ? icon + '#custom_marker' : icon,
  scaledSize: new google.maps.Size(65, 65),
        origin: new google.maps.Point(0, 0),
        anchor: new google.maps.Point(27.5, 27.5), // Anchor at the center of the circular image
  };

    
    const marker = new google.maps.Marker({
      position,
      map,
      title: title,
      icon:image,
      animation: google.maps.Animation.DROP,
      optimized: false,
      
    });
      markersArray.push(marker);
      
      
  
            // Create an info window with custom content.
            const infoWindowContent = document.createElement("div");
            infoWindowContent.innerHTML = title;

            // Add a click event listener to the custom content.
            infoWindowContent.addEventListener("click", () => {
               infoWindow.close();
              // Call your function when the info window content is clicked.
              Hookup4u.postMessage(id);
            });

            const infoWindow = new google.maps.InfoWindow({
              content: infoWindowContent,
            }); // Add the marker to the array

   // Add a click listener for each marker, and set up the info window.
    marker.addListener("click", () => {

   
         infoWindow.close();
     if (currentInfoWindow) {
        currentInfoWindow.close();
    }
   currentInfoWindow1.close();
    // Open the info window.
    infoWindow.open(map, marker);
    currentInfoWindow = infoWindow;

    }
    );
  });

     // Calculate bounds to fit all markers and adjust map
        const bounds = new google.maps.LatLngBounds();
        markersArray.forEach(marker => bounds.extend(marker.getPosition()));
        map.fitBounds(bounds);

        // We get the map's default panorama and set up some defaults.
        // Note that we don't yet set it visible.

        panorama = map.getStreetView(); // TODO fix type
         panorama.setOptions({
          addressControl: false
        });
        panorama.setPosition(currentUserDetails);
        panorama.setPov(
    /** @type {google.maps.StreetViewPov} */ {
                heading: 265,
                pitch: 0,
            }
        );
        
    }

function processSVData({ data }) {
console.log(data)
  const location = data.location;
  const marker = new google.maps.Marker({
    position: location.latLng,
    map,
    title: location.description,
  });

  panorama.setPano(location.pano);
  panorama.setPov({
    heading: 270,
    pitch: 0,
  });
  panorama.setVisible(true);
  marker.addListener("click", () => {
    const markerPanoID = location.pano;

    // Set the Pano to use the passed panoID.
    panorama.setPano(markerPanoID);
    panorama.setPov({
      heading: 270,
      pitch: 0,
    });
    panorama.setVisible(true);
  });
}
</script>

</html>
''';
}
