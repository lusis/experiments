require 'grit'

class Ark::Repo

  def initialize(options = {})
    @options = options
    unless ::File.exists?(File.join(path,'.git'))
      Grit::Repo.init(path)
    end
  end

  # Add the value to the to the store
  #
  # Example
  #   @store.set('key', 'value')
  #
  # Returns nothing
  def set(key, value)
    save("set '#{key}'") do |index|
      index.add(key, value)
    end
  end

  # Shortcut for #set
  #
  # Example:
  #  @store[key] = 'value'
  #
  def []=(key, value)
    set(key, value)
  end

  # Retrieve the value for the given key with a default value
  #
  # Example:
  #  @store.get(key)  #=> value
  #
  # Returns the object found in the repo matching the key
  def get(key, value = nil, *)
    if head && blob = head.commit.tree / key
      blob.data
    end
  end

  # Shortcut for #get
  #
  # Example:
  #   @store['key']  #=> value
  #
  def [](key)
    get(key)
  end

  # Returns an array of key names contained in store
  #
  # Example:
  #  @store.keys  #=> ['key1', 'key2']
  #
  def keys
    head.commit.tree.contents.map{|blob| blob.name }
  end

  # Deletes commits matching the given key
  #
  # Example:
  #  @store.delete('key')
  #
  # Returns nothing
  def delete(key, *)
    self[key].tap do
      save("deleted #{key}") {|index| index.delete(key) }
    end
  end

  # Deletes all contents of the store
  #
  # Returns nothing
  def clear
    save("all clear") do |index|
      if tree = index.current_tree
        tree.contents.each do |entry|
          index.delete(entry.name)
        end
      end
    end
  end

  def dir(top_key)
    contents = git.status.inject([]) {|arr, f| arr << f.path if f.path.split("/")[0] == top_key; arr}
    contents
  end

  # The commit log for the given key
  #
  # Example:
  #  @store.log('key') #=> [{"message"=>"Updated key"...}]
  #
  # Returns Array of commit data
  def log(key)
    git.log(branch, key).map{ |commit| commit.to_hash }
  end

  # Find the key if exists in the git repo
  #
  # Example:
  #  @store.key? 'key'  #=> true
  #
  # Returns true if found; false if not found
  def key?(key)
    !(head && head.commit.tree / key).nil?
  end

  private

  # Given the file path, return a new Grit::Repo if found
  def git
    @git ||= Grit::Repo.new(path)
  end

  # The git branch to use for this store
  def branch
    @options[:branch] || 'master'
  end

  # Checks out the branch on the repo
  def head
    git.get_head(branch)
  end

  # Commits the the value into the git repository with the given commit message
  def save(message)
    index = git.index
    if head
      commit = head.commit
      index.current_tree = commit.tree
    end
    yield index
    index.commit(message, :parents => Array(commit), :head => branch) if index.tree.any?
  end

  # Given that repo path set in the options, return the expanded file path
  def path(key = '')
    @path ||= File.join(File.expand_path(@options[:repo]), key)
  end

end
