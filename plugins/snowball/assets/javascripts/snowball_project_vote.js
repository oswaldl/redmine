$(document).ready(function() {
    var baseObj = $("#snowball-vote-base-url");
    var base = "";

    if(baseObj.length > 0) {
      base = baseObj.val();
    }

    // 这里是每个issue的内页
    if($(".controller-issues").length && $("#snowball-vote").length) {
        var clr = $("<div></div>").css({ clear: "right" });
        var queue = [];
        $("div.issue").each(
            function() {
                queue.push($(this));
            }
        );

        var execQueue = function() {
            if(queue.length) {
                queueStep(queue.shift());
            }
        };

        var queueStep = function(that) {
            var deferred = $.Deferred();
            var vote = $("#snowball-vote").clone().attr({ id: null });
            $(vote).insertBefore("div.issue").show();
            //that.css({ "clear": "both" }).prepend(vote);

            var issue = vote.data("issue");
            //var topic = vote.data("topic");
            var votePoint = vote.find(".snowball-vote-point:first");
            var voteCheck = vote.find(".snowball-vote-check:first");

            $.ajax({
                type: "GET",
                url: base + "issues/" + issue + "/vote",
                cache: false,
                error: function(jqXHR, textStatus, errorThrown) {
                    votePoint.html("-");
                },
                success: function(data, textStatus, jqXHR) {
                    votePoint.html(data.point);
                    voteCheck.html(data.vote ? "☑" : "✅");
                }

            }).always(function() {
                deferred.always();

                vote.find(".snowball-vote-button").bind("click", function(event) {
                    event.preventDefault();
                    var point = $(this).data("point");
                    $.ajax({
                        type: "POST",
                        url: base + "issues/" + issue + "/vote",
                        data: { point: point },
                        cache: false,
                        success: function(data, textStatus, jqXHR) {
                            votePoint.html(data.point);
                            voteCheck.html(data.vote ? "☑" : "✅");
                        }
                    });
                });

                execQueue();
            });
            return deferred.promise();
        };
        execQueue();
    };


    // 这里是每个project的issue列表
    var re = /http(|s)?:\/\/.*\/projects\/.*\/issues/;
    var url = document.URL;
    var result = "#snowball-vote-result";
    var base_proj=$("#snowball-vote-base-project").val();

    if(re.test(url)) {
      $("<div></div>")
        .attr("id", "snowball-vote-result-box")
        .insertAfter($("#content").find("div.contextual"));

      $.ajax({
          type: "GET",
          url: base + "issues/" + base_proj + "/vote/result",
          cache: false,
          success: function(data, textStatus, jqXHR) {
            if($(result).length === 0) {
              var html = $(data).find(result).html();
              if(html) {
                $("#snowball-vote-result-box").addClass("snowball-vote-result").html(html);
              }else {
                $("#snowball-vote-result-box").remove();
              }
            }
          }
      });

      var table = $("table.list.issues.snowball-votes-result-table");

      $("<th></th>")
        .html($("#snowball_label_vote_count").text())
        .insertAfter(table.find("thead > tr > th:nth-child(3)"));

      $("<td></td>")
        .addClass("snowball-vote-td-trigger")
        .insertAfter(table.find("tbody > tr > td:nth-child(3)"));

      /*
      $("td.snowball-vote-td-trigger").each(function() {
        var _re = /\/boards\/([0-9]*)\/topics\/([0-9]*)/;
        var _href = $(this).parent().find("td.subject > a").attr("href");
        var _match = _href.match(_re);
        if(_match) {
          var _board = _match[1];
          var _topic = _match[2];
          var _this = $(this);
          $.ajax({
            type: "GET",
            url: base + "boards/" + _board + "/topics/" + _topic + "/vote",
            cache: false,
            success: function(data, textStatus, jqXHR) {
              _this.html(data.point);
            }
          });
        }
      });
      */
    }
});
