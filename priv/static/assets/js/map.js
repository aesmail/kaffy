$(document).ready(function() {
  const Map = {
    loaded: false
    , startLat: 51.5358025
    , startLng: 0.0198837000000367
    , init: function() {
      if (!Map.loaded) {
        mapKey = $("meta[name='gmap-api-key']").attr('content');

        if (mapKey) {
          var script = document.createElement('script');
          script.src = `https://maps.googleapis.com/maps/api/js?key=${mapKey}&callback=mapLoadedCallback`;
          script.async = true;

          document.head.appendChild(script);
        } else {
          alert("Please set a meta tag in your markup containing your Google Maps API key: meta[name='gmap-api-key']")
        }
      }
    }
    , loadedCallback: function() {
      console.log('Map.loadedCallback !!! ----------------------------------------------');
      Map.loaded = true;

      let map;
      let marker1;
      let marker2;

      let topLat = $('*[data-field-name="map_marker_1_lat"]').val() || Map.startLat + 0.2;
      let topLon = $('*[data-field-name="map_marker_1_lon"]').val() || Map.startLng;
      let btmLat = $('*[data-field-name="map_marker_2_lat"]').val() || Map.startLat;
      let btmLon = $('*[data-field-name="map_marker_2_lon"]').val() || Map.startLng + 0.3;

      map = new google.maps.Map(document.getElementById("map"), {
        center: { lat: Map.startLat, lng: Map.startLng },
        zoom: 8,
      });

      // Plot two markers to represent the Rectangle's bounds.
      marker1 = new google.maps.Marker({
        map: map,
        position: new google.maps.LatLng(topLat, topLon),
        draggable: true,
        title: 'Drag me! MK1'
      });
      marker2 = new google.maps.Marker({
        map: map,
        position: new google.maps.LatLng(btmLat, btmLon),
        draggable: true,
        title: 'Drag me! MK2'
      });

      // Allow user to drag each marker to resize the size of the Rectangle.
      google.maps.event.addListener(marker1, 'drag',
        function() {
          Map.redraw(marker1, marker2)
        });
      google.maps.event.addListener(marker2, 'drag',
        function() {
          Map.redraw(marker1, marker2)
        });

      // Create a new Rectangle overlay and place it on the map.  Size
      // will be determined by the LatLngBounds based on the two Marker
      // positions.
      rectangle = new google.maps.Rectangle({
        map: map
      });

      Map.redraw(marker1, marker2);
    }
    , redraw: function(marker1, marker2) {
      var latLngBounds = new google.maps.LatLngBounds(
        marker1.getPosition(),
        marker2.getPosition()
      );

      rectangle.setBounds(latLngBounds);

      $('#top-corner').html(marker1.getPosition().lat() + "::" + marker1.getPosition().lng());
      $('#bot-corner').html(marker2.getPosition().lat() + "::" + marker2.getPosition().lng());

      Map.populateBounds(marker1, marker2);
    }
    , populateBounds: function(marker1, marker2) {
      $('*[data-field-name="map_marker_1_lat"]').val(marker1.getPosition().lat());
      $('*[data-field-name="map_marker_1_lon"]').val(marker1.getPosition().lng());
      $('*[data-field-name="map_marker_2_lat"]').val(marker2.getPosition().lat());
      $('*[data-field-name="map_marker_2_lon"]').val(marker2.getPosition().lng());

      var filterForm = $("#kaffy-filters-form");
      filterForm.children("input#custom-filter-map_marker_1_lat").val(marker1.getPosition().lat());
      filterForm.children("input#custom-filter-map_marker_1_lon").val(marker1.getPosition().lng());
      filterForm.children("input#custom-filter-map_marker_2_lat").val(marker2.getPosition().lat());
      filterForm.children("input#custom-filter-map_marker_2_lon").val(marker2.getPosition().lng());
      // filterForm.submit();
    }
  }

  var modalMap = document.getElementById('modalMap');
  if (modalMap) {
    modalMap.addEventListener('show.bs.modal', function(event) {
      console.log('show.bs.modal ----------------------------------------------');

      Map.init();

      // Attach your callback function to the `window` object
      window.mapLoadedCallback = function() { Map.loadedCallback(); };
    });
  }
});
