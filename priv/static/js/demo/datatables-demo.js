// Call the dataTables jQuery plugin
$(document).ready(function () {
  var api_url = $("#kaffy-api-url").html();

  $('#dataTable').DataTable({
    "processing": true,
    "serverSide": true,
    "ordering": false,
    "ajax": api_url,
  });

  if ($("a#pick-raw-resource").length) {
    $("a#pick-raw-resource").click(function () {
      var link = $(this).attr("href");
      console.log(link);
      window.open(link, "_blank");
      return false;
    });
  }

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
});
