// Call the dataTables jQuery plugin
$(document).ready(function () {
  var api_url = $("#kaffy-api-url").html();
  var columnNames = $("#column-names").text();
  var columnNames = columnNames.split(',')
  var tableColumnNames = columnNames.map(function (value, _index, _arr) {
    return { name: value };
  });

  $('#dataTable').DataTable({
    "processing": true,
    "serverSide": true,
    "ordering": false,
    "columns": tableColumnNames,
    "ajax": api_url,
    initComplete: function () {
      var dtApi = this.api();
      $(".kaffy-filter").each(function () {
        var selectFilter = $(this);
        var columnIndex = selectFilter.attr('id').split('-')[2];
        var columnName = selectFilter.data('field-name');
        var column = dtApi.columns(columnIndex);
        selectFilter.on('change', function () {
          var val = $(this).val();
          column.search(val ? val : '', false, false).draw();
        });
      });
    }
  });

  if ($("a#pick-raw-resource").length) {
    $("a#pick-raw-resource").click(function () {
      var link = $(this).attr("href");
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
});
