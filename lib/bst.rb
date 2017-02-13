class BSTNode
  attr_accessor :left, :right
  attr_reader :value

  def initialize(value)
    @value = value
    @left = nil
    @right = nil
  end
end

class BinarySearchTree
  def initialize
    @root = BSTNode.new(nil)
  end

  def insert(value)
    if @root.value
      BinarySearchTree.insert!(@root, value)
    else
      @root = BSTNode.new(value)
    end
  end

  def find(value)
    BinarySearchTree.find!(@root, value)
  end

  def inorder
    BinarySearchTree.inorder!(@root)
  end

  def postorder
    BinarySearchTree.postorder!(@root)
  end

  def preorder
    BinarySearchTree.preorder!(@root)
  end

  def height
    BinarySearchTree.height!(@root)
  end

  def min
    BinarySearchTree.min(@root)
  end

  def max
    BinarySearchTree.max(@root)
  end

  def delete(value)
    @root = BinarySearchTree.delete!(@root, value)
  end

  def self.insert!(node, value)
    return BSTNode.new(value) unless node
    if value > node.value
      if node.right
        BinarySearchTree.insert!(node.right, value)
      else
        node.right = BSTNode.new(value)
      end
    elsif node.left
      BinarySearchTree.insert!(node.left, value)
    else
      node.left = BSTNode.new(value)
    end
    node
  end

  def self.find!(node, value)
    return nil unless node && node.value
    return node if node.value == value
    if value > node.value
      BinarySearchTree.find!(node.right, value)
    else
      BinarySearchTree.find!(node.left, value)
    end
  end

  def self.preorder!(node)
    return [] unless node
    [node.value] +
    BinarySearchTree.preorder!(node.left) +
    BinarySearchTree.preorder!(node.right)
  end

  def self.inorder!(node)
    return [] unless node
    BinarySearchTree.inorder!(node.left) +
    [node.value] +
    BinarySearchTree.inorder!(node.right)
  end

  def self.postorder!(node)
    return [] unless node
    BinarySearchTree.postorder!(node.left) +
    BinarySearchTree.postorder!(node.right) +
    [node.value]
  end

  def self.height!(node)
    return -1 unless node && node.value
    left = 0
    right = 0
    left += 1 + BinarySearchTree.height!(node.left)
    right += 1 + BinarySearchTree.height!(node.right)
    left > right ? left : right
  end

  def self.max(node)
    return nil unless node
    return node unless node.right
    BinarySearchTree.max(node.right)
  end

  def self.min(node)
    return nil unless node
    return node unless node.left
    BinarySearchTree.min(node.left)
  end

  def self.delete_min!(node)
    return nil unless node
    if node.left == BinarySearchTree.min(node)
      node.left = node.left.right
    else
      BinarySearchTree.delete_min!(node.left)
    end
  end

  def self.delete!(node, value)
    return nil unless node

    if node.value < value
      node.right = BinarySearchTree.delete!(node.right, value)
    elsif node.value > value
      node.left = BinarySearchTree.delete!(node.left, value)
    else
      return node.left unless node.right
      return node.right unless node.left

      target = node
      node = target.right.min
      node.right = BinarySearchTree.delete_min!(target.right)
      node.left = target.left
    end
    node
  end
end
