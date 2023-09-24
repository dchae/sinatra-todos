$(document).ready(function () {
  $("form.delete").submit(function (event) {
    event.preventDefault();
    event.stopPropagation();

    var ok = confirm("Are you sure?");
    if (ok) {
      var form = $(this);

      var request = $.ajax({
        url: form.attr("action"),
        method: form.attr("method"),
      });

      request.done(function (data, textStatus, jqXHR) {
        if (jqXHR.status === 204) {
          form.parent("li").fadeOut(200);
        } else if (jqXHR.status === 200) {
          document.location = data;
        }
      });
      // handle request fail
      // request.fail(function () {});
    }
  });
});
