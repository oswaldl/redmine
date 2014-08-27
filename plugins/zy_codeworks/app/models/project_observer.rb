
# create by oswaldl for testing Observer

class ProjectObserver < ActiveRecord::Observer
  observe :Project

  def after_save(obj)
    #Notifications.comment("admin@do.com", "New comment was posted", comment).deliver
    puts "got it #{obj}............."
  end
end