class Blog < ActiveRecord::Base
  attr_accessible :content, :title

  validates :content, presence: true

  def as_json(options)
    {
      title: title,
      content: content
    }
  end
end
