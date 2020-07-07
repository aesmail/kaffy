$(document).ready(function () {
  Chart.defaults.global.defaultFontFamily = '-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';
  Chart.defaults.global.defaultFontColor = '#292b2c';

  $(".kaffy-editor").each(function () {
    var textareaId = "#" + $(this).attr('id');
    ClassicEditor
      .create(document.querySelector(textareaId), {
        // toolbar: [ 'heading', '|', 'bold', 'italic', 'link' ]
        toolbar: ['heading', '|', 'bold', 'italic', 'link', 'bulletedList', 'numberedList', 'blockQuote', '|', 'indent', 'outdent', '|', 'insertTable', '|', 'undo', 'redo']
      })
      .then(editor => {
        window.editor = editor;
      })
      .catch(err => {
        console.error(err.stack);
      });
  });

  $(".kaffy-filter").change(function () {
    var selectFilter = $(this);
    var fieldName = selectFilter.data('field-name');
    var fieldValue = selectFilter.val();
    var filterForm = $("#kaffy-filters-form");
    filterForm.children("input#custom-filter-" + fieldName).val(fieldValue);
    filterForm.submit();
  });

  $(".list-action").submit(function () {
    var actionForm = $(this);
    var selected = $.map($("input.kaffy-resource-checkbox:checked"), function (e) {
      return $(e).val();
    }).filter(function (n) {
      return n != "";
    }).join();

    $("<input />").attr("type", "hidden").attr("name", "ids").attr("value", selected).appendTo(actionForm);

    return true;
  });

  $('#kaffy-search-field').on('keypress', function (e) {
    if (e.which === 13) {
      var value = $(this).val();
      var filterForm = $("#kaffy-filters-form");
      filterForm.children("input#kaffy-filter-search").val(value);
      filterForm.submit();
    }
  });

  $("#kaffy-search-form").submit(function (event) {
    var value = $("#kaffy-search-field").val();
    var filterForm = $("#kaffy-filters-form");
    filterForm.children("input#kaffy-filter-search").val(value);
    filterForm.submit();
    event.preventDefault();
  });

  $("a#pick-raw-resource").click(function () {
    var link = $(this).attr("href");
    window.open(link, "_blank");
    return false;
  });

  if ($("div#pick-resource").length) {
    $("body").on("click", "td a", function () {
      var link = $(this);
      var theParent = $(window.opener.document);
      var field_name = $("#pick-field-name").html();
      var path_parts = link.attr("href").split("/");
      var record_id = path_parts[path_parts.length - 1];
      var field_id = "input#" + field_name;
      theParent.find(field_id).val(record_id);
      window.close();
      return false;
    });
  }

  $("a.kaffy-order-field").click(function () {
    var a = $(this);
    var field = a.data('field');
    var order = a.data('order');
    var filterForm = $("#kaffy-filters-form");
    filterForm.children("input#kaffy-order-field").val(field);
    filterForm.children("input#kaffy-order-way").val(order);
    filterForm.children("input#kaffy-filter-page").val(1);
    filterForm.submit();
    event.preventDefault();
  })

  $(".kaffy-chart").each(function () {
    var currentChart = $(this);
    var chartId = currentChart.children("canvas").first().attr('id');
    var xAxis = currentChart.children("div.values").first().children("span.x-axis").first().text().split(",");
    var yTitle = currentChart.children("div.values").first().children("span.y-title").first().text();
    var yAxis = currentChart.children("div.values").first().children("span.y-axis").first().text().split(",").map(function (value) { return Number(value); });
    var ctx = document.getElementById(chartId);

    new Chart(ctx, {
      type: 'line',
      data: {
        labels: xAxis,
        datasets: [{
          label: yTitle,
          lineTension: 0.3,
          backgroundColor: "rgba(2,117,216,0.2)",
          borderColor: "rgba(2,117,216,1)",
          pointRadius: 5,
          pointBackgroundColor: "rgba(2,117,216,1)",
          pointBorderColor: "rgba(255,255,255,0.8)",
          pointHoverRadius: 5,
          pointHoverBackgroundColor: "rgba(2,117,216,1)",
          pointHitRadius: 50,
          pointBorderWidth: 2,
          data: yAxis,
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        layout: {
          padding: {
            left: 10,
            right: 25,
            top: 25,
            bottom: 0
          }
        },
        scales: {
          xAxes: [{
            // time: {
            //   unit: 'date'
            // },
            gridLines: {
              display: false,
              drawBorder: false
            },
            ticks: {
              maxTicksLimit: 7
            }
          }],
          yAxes: [{
            ticks: {
              maxTicksLimit: 5,
              padding: 10,
              // Include a dollar sign in the ticks
              // callback: function (value, index, values) {
              //   return '$' + number_format(value);
              // }
            },
            gridLines: {
              color: "rgb(234, 236, 244)",
              zeroLineColor: "rgb(234, 236, 244)",
              drawBorder: false,
              borderDash: [2],
              zeroLineBorderDash: [2]
            }
          }],
        },
        legend: {
          display: false
        },
        tooltips: {
          backgroundColor: "rgb(255,255,255)",
          bodyFontColor: "#858796",
          titleMarginBottom: 10,
          titleFontColor: '#6e707e',
          titleFontSize: 14,
          borderColor: '#dddfeb',
          borderWidth: 1,
          xPadding: 15,
          yPadding: 15,
          displayColors: false,
          intersect: false,
          mode: 'index',
          caretPadding: 10,
          // callbacks: {
          //   label: function (tooltipItem, chart) {
          //     var datasetLabel = chart.datasets[tooltipItem.datasetIndex].label || '';
          //     return datasetLabel + ': $' + number_format(tooltipItem.yLabel);
          //   }
          // }
        }
      }
    });
  });
});