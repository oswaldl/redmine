class SnowballProjectVote < ActiveRecord::Base
  # def vote(answer)
  #   increment(answer == 'yes' ? :yes : :no)
  # end

  def add_vote(issue_id, user_id, point = 0)
    votes = SnowballProjectVote.where(:issue_id => issue_id, :user_id => user_id).first
    if votes
      votes.point = point.nil? ? 0 : point
      votes.save!
    else
      votes = SnowballProjectVote.new
      votes.issue_id = issue_id
      votes.user_id = user_id
      votes.point = point.nil? ? 0 : point
      votes.save!
    end

    return get_point(issue_id)
  end

  def get_point(issue_id)
    return SnowballProjectVote.sum(:point, :conditions => ['issue_id = ?', issue_id])
  end


  def get_points(user_id, issue_id)
    return result = {
        "plus" => SnowballProjectVote.sum(:point, :conditions => ['issue_id = ? and point > 0', issue_id]),
        "minus" => SnowballProjectVote.sum(:point, :conditions => ['issue_id = ? and point < 0', issue_id]),
        "zero" => SnowballProjectVote.sum(:point, :conditions => ['issue_id = ? and point = 0', issue_id]),
        "vote" => SnowballProjectVote.count(:point, :conditions => ['issue_id = ? and user_id = ?', issue_id, user_id]),
    }
  end
end
