atom_feed(
  :url         => url_for(formatted_posts_path(:tag => @tag, :format => 'atom', :only_path => false)), 
  :root_url    => url_for(posts_path(:tag => @tag, :only_path => false)),
  :schema_date => '2008'
) do |feed|
  feed.title     posts_title(@tag)
  feed.updated   @posts.empty? ? Time.now.utc : @posts.collect(&:updated_at).max
  feed.generator "Enki", "uri" => "http://enkiblog.com"

  feed.author do |xml|
    xml.name  author.name
    xml.email author.email unless author.email.nil?
  end

  @posts.each do |post|
   feed.entry(post, :url => post_path(post), :published => post.published_at) do |entry|
      entry.title   post.title
      entry.content post.body_html, :type => 'html'
    end
  end
end
