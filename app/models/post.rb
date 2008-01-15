class Post < ActiveRecord::Base
  DEFAULT_LIMIT = 15

  acts_as_defensio_article 
  acts_as_taggable

  has_many :comments
  has_many :approved_comments, :class_name => 'Comment', :conditions => 'comments.spam = 0'

  before_create :generate_slug
  before_save   :apply_filter

  validates_presence_of :title
  validates_presence_of :body

  class << self
    def find_recent(options = {})
      tag = options.delete(:tag)
      options = {
        :order      => 'posts.published_at DESC',
        :conditions => ['published_at < ?', Time.now],
        :limit      => DEFAULT_LIMIT
      }.merge(options)
      if tag
        find_tagged_with(tag, options)
      else
        find(:all, options)
      end
    end

    def find_by_permalink(year, month, day, slug)
      begin
        day = Time.parse([year, month, day].collect(&:to_i).join("-")).midnight
        post = find_all_by_slug(slug).detect do |post|
          post.published_at.midnight == day
        end 
      rescue ArgumentError # Invalid time
        post = nil
      end
      post || raise(ActiveRecord::RecordNotFound)
    end

    def find_all_grouped_by_month
      posts = find(
        :all,
        :order      => 'posts.published_at DESC',
        :conditions => ['published_at < ?', Time.now]
      )
      month = Struct.new(:date, :posts)
      posts.group_by(&:month).inject([]) {|a, v| a << month.new(v[0], v[1])}
    end
  end

  def month
    published_at.beginning_of_month
  end

  def apply_filter
    self.body_html = Lesstile.format_as_xhtml(
      self.body,
      :text_formatter => lambda {|text| RedCloth.new(text).to_html},
      :code_formatter => Lesstile::CodeRayFormatter
    )  
  end

  def denormalize_comments_count!
    self.approved_comments_count = self.approved_comments.count
    self.save!
  end

  protected

  def generate_slug
    self.slug ||= self.title
    self.slug.slugorize!
  end
end
