class Comment < ActiveRecord::Base
  belongs_to :discussion
  belongs_to :parent, class_name: 'Comment'
  has_many :children, class_name: "Comment", foreign_key: "parent_id", dependent: :destroy
  has_many :points, dependent: :destroy

  def ordered_children
    children.order('votes DESC')
  end
end
