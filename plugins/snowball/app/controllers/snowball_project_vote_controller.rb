class SnowballProjectVoteController < ApplicationController
  unloadable

  before_filter :find_user
  before_filter :init_votes

  MAX_VOTELIST = 5

  def index
    params[:project_id] && @project = Project.find(params[:project_id])
    @votes = SnowballProjectVote.all
  end


  def hello
    params[:project_id] && @project = Project.find(params[:project_id])

  end

  # Add vote
  def add
    find_project_and_issue

    if ['-1', '1', '0'].include? params[:point] then
      @point = @votes.add_vote(@issue.id, @user.id, params[:point])
    end

    get
  end

  # Get vote by id
  def get
    find_project_and_issue

#    @point = @votes.get_point(@message.id)
    result = @votes.get_points(@user.id, @issue.id)
    result['point'] = result['plus'] + result['minus']
    render :json => result
  end


  # Get result in list
  def result
    @project = Project.find(params[:project_id])
    @votes = SnowballProjectVote\
      .select('issue_id, sum(point) as sump')\
      .joins('right join issues on issues.project_id = %s and snowball_project_votes.issue_id = issues.id' % @project.id)\
      .group('issue_id')\
      .order('sum(point) desc, issues.id desc')\
      .limit(MAX_VOTELIST)

    issues = Array.new
    @votes_issues = {}
    @votes.each do |v|
      issues.push(v.issue_id)
      @votes_issues[v.issue_id] = v.sump
    end

    @voted_issue = @project.issues\
      .joins('inner join (select issue_id, sum(point) as sump from snowball_project_votes group by issue_id) as votes on issues.id = votes.issue_id')\
      .where('issues.id' => issues)\
      .reorder('votes.sump desc, issues.id desc')
  end

private

  def init_votes
    @votes = SnowballProjectVote.new
  end

  def find_user
    @user = User.current
  end

  def find_project_and_issue

    begin
      @issue = Issue.find(params[:issue_id])
      @project = @issue.project

      logger.info "find_project_and_issue #{@project}, #{@issue}"

    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end

end
