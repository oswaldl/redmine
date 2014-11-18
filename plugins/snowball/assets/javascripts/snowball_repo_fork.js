$(document).ready(function() {
    $('.contextual').prepend($('#repo_github_extra').detach());

    $('#fork_from_section').detach().insertAfter($('.contextual').next());
});
