class Blog < ActiveRecord::Base
  attr_accessible :content, :title

  def as_json(options)
    {
      title: title,
      content: content
    }
  end
end
