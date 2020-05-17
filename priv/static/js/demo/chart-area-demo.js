Chart.defaults.global.defaultFontFamily = 'Nunito', '-apple-system,system-ui,BlinkMacSystemFont,"Segoe UI",Roboto,"Helvetica Neue",Arial,sans-serif';
Chart.defaults.global.defaultFontColor = '#858796';

// Area Chart Example
$(document).ready(function () {
  $(".kaffy-chart").each(function () {
    var currentChart = $(this);
    var chartId = $(this).children("canvas").first().attr('id');
    var xAxis = $(this).children("div.values").first().children("span.x-axis").first().text().split(",");
    var yTitle = $(this).children("div.values").first().children("span.y-title").first().text();
    var yAxis = $(this).children("div.values").first().children("span.y-axis").first().text().split(",").map(function (value) { return Number(value); });


    var ctx = document.getElementById(chartId);
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: xAxis,
        datasets: [{
          label: yTitle,
          lineTension: 0.3,
          backgroundColor: "rgba(78, 115, 223, 0.05)",
          borderColor: "rgba(78, 115, 223, 1)",
          pointRadius: 3,
          pointBackgroundColor: "rgba(78, 115, 223, 1)",
          pointBorderColor: "rgba(78, 115, 223, 1)",
          pointHoverRadius: 3,
          pointHoverBackgroundColor: "rgba(78, 115, 223, 1)",
          pointHoverBorderColor: "rgba(78, 115, 223, 1)",
          pointHitRadius: 10,
          pointBorderWidth: 2,
          data: yAxis,
        }],
      },
      options: {
        maintainAspectRatio: false,
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
