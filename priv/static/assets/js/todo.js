(function ($) {
  'use strict';
  var $this = $(".todo-list .todo-item");
  $(".todo-list .todo-item:not(.edit-mode)").append('<div class="edit-icon"><i class="mdi mdi-pencil"></i></div>');

  $(".edit-icon").on("click", function () {
    $(this).parent().addClass("edit-mode");
    $(".todo-list .todo-item button[type='reset']").on("click", function () {
      $(this).closest(".todo-item").addClass("edit-mode");
    });
  });

})(jQuery);