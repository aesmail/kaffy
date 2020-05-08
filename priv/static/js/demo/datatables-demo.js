// Call the dataTables jQuery plugin
$(document).ready(function () {
  var api_url = $("#kaffy-api-url").html();

  $('#dataTable').DataTable({
    "processing": true,
    "serverSide": true,
    "ordering": false,
    "ajax": api_url,
  });
});
