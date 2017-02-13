class AVLTreeNode
  attr_accessor :link, :balance, :value

  def initialize(value)
    @value = value
    @subtrees = [nil, nil]
    @balance = 0
  end
end

class AVLTree
  def initialize
    @root = nil
  end

  def insert(value)
    done = false
    @root, done = AVLTree.insert!(@root, value, done)
    true
  end

  def insert_unbounded(value)
    done = false
    @root, done = AVLTree.insert!(@root, value, done)
    true
  end

  def remove(value)
    done = false
    @root, done = AVLTree.remove!(@root, value, done)
    true
  end

  def remove_unbounded(value)
    done = false
    @root, done = AVLTree.remove_unbounded!(@root, value, done)
    true
  end

  def height
    AVLTree.height!(@root)
  end

  def self.insert!(node, value, done)
    return [AVLTreeNode.new(value), false] unless node

    dir = value < node.value ? 0 : 1
    node.subtrees[dir], done = AVLTree.insert!(node.subtrees[dir], value, done)

    unless done
      node.balance += (dir == 0 ? -1 : 1)

      if node.balance == 0
        done = true
      elsif node.balance.abs > 1
        node = AVLTree.insert_balance!(node, dir)
        done = true
      end
    end

    [node, done]
  end

  def self.single_rotation!(root, dir)
    other_dir = dir == 0 ? 1 : 0

    new_root = root.subtrees[other_dir]
    root.subtrees[other_dir] = new_root.subtrees[dir]
    new_root.subtrees[dir] = root

    new_root
  end

  def self.double_rotation!(root, dir)
    other_dir = dir == 0 ? 1 : 0

    pivot = root.subtrees[other_dir].subtrees[dir]
    root.subtrees[other_dir].subtrees[dir] = pivot.subtrees[other_dir]
    pivot.subtrees[other_dir] = root.subtrees[other_dir]

    root.subtrees[other_dir] = pivot
    new_root = root.subtrees[other_dir]
    root.subtrees[other_dir] = new_root.subtrees[dir]

    new_root.subtrees[dir] = root
  end

  def self.adjust_balance!(root, dir, bal)
    other_dir = dir == 0 ? 1 : 0

    n = root.subtrees[dir]
    n_subs = n.subtrees[other_dir]

    if n_subs.balance == 0
      root.balance, n.balance = 0, 0
    elsif n_subs.balance == bal
      root.balance, n.balance = -bal, 0
    else
      root.balance, n.balance = 0, bal
    end

    nn.balance = 0
  end

  def self.insert_balance!(root, dir)
    other_dir = dir == 0 ? 1 : 0

    n = root.subtrees[dir]
    bal = dir == 0 ? -1 : +1

    if n.balance == bal
      root.balance, n.balance = 0, 0
      root = AVLTree.single_rotation!(root, other_dir)
    else
      AVLTree.adjust_balance!(root, dir, bal)
      root = AVLTree.double_rotation!(root, other_dir)
    end

    root
  end

  def self.remove_balance!(root, dir, done)
    other_dir = dir == 0 ? 1 : 0

    n = root.subtrees[other_dir]
    bal = dir == 0 ? -1 : 1

    if n.balance == -bal
      root.balance, n.balance = 0, 0
      root = AVLTree.single_rotation!(root, dir)
    elsif n.balance == bal
      AVLTree.adjust_balance!(root, other_dir, -bal)
      root = AVLTree.double_rotation!(root, dir)
    else
      root.balance, n.balance = -bal, bal
      root = AVLTree.single_rotation!(root, dir)
      done = true
    end

    [root, done]
  end

  def self.remove!(root, value, done)
    if root
      if root.value == value
        if root.subtrees[0].nil? || root.subtrees[1].nil?
          dir = root.subtrees[0].nil? ? 1 : 0
          save = root.subtrees[dir]

          return [save, done]
        else
          heir = root.subtrees[0]
          until heir.subtrees[1].nil?
            heir = heir.subtrees[1]
          end

          root.value = heir.value
          value = heir.value
        end
      end

      dir = value < root.value ? 0 : 1
      root.subtrees[dir], done = AVLTree.remove!(
        root.subtrees[dir],
        value,
        done
      )

      unless done
        root.balance += (dir != 0 ? -1 : 1)

        if root.balance.abs == 1
          done = true
        elsif root.balance.abs > 1
          root, done = AVLTree.remove_balance!(root, dir, done)
        end
      end
    end

    [root, done]
  end

  def self.height!(root)
    return -1 unless root

    root.balance
  end

  def self.single_rotation_unbounded!(root, dir)
    other_dir = dir == 0 ? 1 : 0

    new_root = root.subtrees[other_dir]

    root.subtrees[other_dir] = new_root.subtrees[dir]
    new_root.subtrees[dir] = root

    root_left_height = AVLTree.height!(root.subtrees[0])
    root_right_height = AVLTree.height!(root.subtrees[1])
    new_root_left_height = AVLTree.height!(new_root.subtrees[other_dir])

    root.balance = [root_left_height, root_right_height].max + 1
    new_root.balance = [new_root_left_height, root.balance].max + 1

    new_root
  end

  def self.double_rotation_unbounded!(root, dir)
    other_dir = dir == 0 ? 1 : 0
    root.subtrees[other_dir] = AVLTree.single_rotation_unbounded!(
      root.subtrees[other_dir],
      other_dir
    )
    AVLTree.single_rotation_unbounded!(root, dir)
  end

  def self.insert_unbounded!(root, value, done)
    return [AVLTreeNode.new(value), false] unless root

    dir = value < root.value ? 0 : 1
    other_dir = dir == 0 ? 1 : 0

    root.subtrees[dir], done = AVLTree.insert_unbounded!(
      root.subtrees[dir],
      value,
      done
    )

    unless done
      left_height = AVLTree.height!(root.subtrees[dir])
      right_height = AVLTree.height!(root.subtrees(other_dir))

      if (left_height - right_height) >= 2
        a = root.subtrees[dir].subtrees[dir]
        b = root.subtrees[dir].subtrees[other_dir]

        if AVLTree.height!(a) >= AVLTree.height!(b)
          root = AVLTree.single_rotation_unbounded!(root, other_dir)
        else
          root = AVLTree.double_rotation_unbounded!(root, other_dir)
        end
        done = true
      end

      left_height = AVLTree.height!(root.subtrees[dir])
      right_height = AVLTree.height!(root.subtrees[other_dir])
      max = [left_height, right_height].max

      root.balance = max + 1
    end

    [root, done]
  end

  def self.remove_unbounded!(root, value, done)
    if root
      if root.value == value
        if root.subtrees[0].nil? || root.subtrees[1].nil?
          dir = root.subtrees[0].nil? ? 1 : 0
          save = root.subtrees[dir]

          return [save, done]
        else
          heir = root.subtrees[0]

          until heir.subtrees[1].nil?
            heir = heir.subtrees[1]
          end

          root.value = heir.value
          value = heir.value
        end
      end

      dir = value < root.value ? 0 : 1
      other_dir = dir == 0 ? 1 : 0

      root.subtrees[dir], done = AVLTree.remove_unbounded!(root.subtrees[dir], value, done)

      unless done
        left_height = AVLTree.height!(root.subtrees[dir])
        rh = AVLTree.height!(root.subtrees[other_dir])
        max = [left_height, rh].max

        root.balance = max + 1

        if (left_height - rh) == -1
          done = true
        end

        if (left_height - rh) <= -2
          a = root.subtrees[other_dir].subtrees[dir]
          b = root.subtrees[other_dir].subtrees[other_dir]

          if AVLTree.height!(a) <= AVLTree.height!(b)
            root = AVLTree.single_rotation_unbounded!(root, dir)
          else
            root = AVLTree.double_rotation_unbounded!(root, dir)
          end
        end
      end
    end

    [root, done]
  end
end
