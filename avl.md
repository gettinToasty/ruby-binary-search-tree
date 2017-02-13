## AVL Tree

An AVL tree is a self-balancing binary search tree. For any node, the heights of its two subtrees may differ by at most one. Instead of allowing insertion order alone to determine depth, it rebalances itself to maintain this property and a depth of `O(log(n))`.

This will be a bit different than our other projects. It will be a walkthrough that will cover, often in detail, the concept behind AVL Trees and implementation issues with a practical eye. Please follow along with your own implementation, testing along the way.

This walkthrough won't go into proof based analysis. If you are interested in that though, an excellent analysis of AVL Trees is made in Donald Knuth's "The Art of Computer Programming, Volume 3".

### Initial Setup

Let's think about what information each node must contain.
Each node will be the root of a subtree, with subtreess to at most two subtrees.
In this implementation, we'll use an array of 2 subtrees rather than 2 separate subtrees to reduce redundancy later.

```ruby
class AVLTreeNode
  attr_accessor :subtrees, :value

  def initialize(value)
    @value = value
    @subtrees = [nil, nil]
  end
end
```

The whole point is to avoid symmetric cases. Balanced tree algorithms can be very verbose because code needs to be duplicated for both the left and right subtree cases.
Take a look at this classic implementation.

```ruby
class AVLTreeNode
  attr_accessor :left, :right, :value

  def initialize(value)
    @value = value
    @left_subtree = nil
    @right_subtree = nil
  end
end

class AVLTree
  def initialize
    @root = nil
  end

  def insert(value)
    @root = AVLTree.insert!(@root, value)
  end

  def self.insert!(node, value)
    return AVLTreeNode.new(value) unless node

    if value < node.value
      node.left = AVLTree.insert!(node.left, value)
      # Fifty lines of left balancing node
    else
      node.right = AVLTree.insert!(node.right, value)
      # Fifty lines of right balancing node
    end

    node
  end
end
```
Rather than suffer these symmetric cases, we prefer to merge them into a
single case through the use of an easily computed array index.
Our implementation merges the left and right cases into one:
subtrees[0] is the left case and
subtrees[1] is the right case.

```ruby
class AVLTreeNode
  attr_accessor :subtrees, :value

  def initialize(value)
    @value = value
    @subtrees = [nil, nil]
  end
end

class AVLTree
  def initialize
    @root = nil
  end

  def insert(value)
    @root = AVLTree.insert!(@root, value)
  end

  def self.insert!(node, value)
    return AVLTreeNode.new(value) unless node

    dir = value < node.value ? 0 : 1

    node.subtrees[dir] = AVLTree.insert!(node.subtrees[dir], value)
    # Fifty lines of dir balancing code

    node
  end
end
```

How does the comparison for calculating a direction index work? Put simply, if you want to move down the right subtree, ensure that the comparison results in 1, otherwise the comparison will result in 0 and you will move down the left subtree.

### Tree Rotations

The AVL tree requires that the height of each node's subtrees must differ by no more than 1. In the following diagram, the first two trees are AVL trees but the third is not because the left subtree of 5 has a height of 2 while the right subtree is a null subtrees and has a height of 0:

```
          3                        5                  5

      /       \                 /     \             /

    1           5             3         7         3

  /   \       /   \             \                   \

 0    2     4       6             4                   4
```
If a subtree loses its balance due to insertion or deletion, we can rotate the nodes to rebalance it.

#### Single Rotation

If a subtree is too long in the same direction, a single rotation can bring the structure back into balance without breaking the binary search tree invariant. In the next diagram, a left rotation at 3 is made to bring the subtree into balance:

```
3                     4

   \                /   \

     4       -->   3       6

    /   \           \

  5       6           5
```

The code to perform a single rotation is simple. We must rotate in the correct direction and transfer the children of the affected nodes. A left rotation (such as above) will find dir as 0 when the function is called. In this rotation, root would be 3, and new_root would be 4. The function returns the new root for reassignment into the tree.

```ruby
# root = 3
# dir = 0
def self.single_rotation!(root, dir)
  other_dir = dir == 0 ? 1 : 0 # 1
  new_root = root.subtrees[other_dir] # 4

  root.subtrees[other_dir] = new_root.subtrees[dir]
  # assign new_root's (4's) left subtree to root's (3's) right subtree

  new_root.subtrees[dir] = root
  # assign 3 as 4's left subtree

  new_root
end
```

#### Double Rotation

If a subtree is too long in the opposite direction, two rotations are required to return the structure to balance. The first rotation is at the subtree, then the second is at the root. Notice how the binary search tree invariant is maintained throughout the entire operation, including the intermediate step of the first rotation:

```

 3             3                     4

   \             \                 /   \

     5   -->       4       -->   3       5

   /                 \

 4                     5
```
We can call `AVLTree.single_rotation!` twice in the body of `AVLTree.double_rotation!` to achieve the correct structure.
To better show how a double rotation works, let's hardcode the operations
for now:

```ruby
# root = 3
# dir = 0
def self.double_rotation!(root, dir)
  # first right-rotate at 5's subtree
  other_dir = dir == 0 ? 1 : 0 #1
  pivot = root.subtrees[other_dir].subtrees[dir] #4

  root.subtrees[other_dir].subtrees[dir] = pivot.subtrees[other_dir]
  # assign 5's left subtree to 4's right subtree (nil)

  pivot.subtrees[other_dir] = root.subtrees[other_dir]
  #assign 4's right subtree to 3's right subtree (5)

  root.subtrees[other_dir] = pivot
  #assign 5's right subtree to 4

  # now do the left-rotation at 3
  new_root = root.subtrees[other_dir] #4
  root.subtrees[other_dir] = new_root.subtrees[dir]
  #assign 3's right subtree to 4's left subtree (nil)

  new_root.subtrees[dir] = root
  #assign 4's left subtree to 3
end
```

## Balancing Trees

How do we know when a subtree is out of balance and should be rotated?
Let's store extra balance information in each node.

```ruby
class AVLTreeNode
  attr_accessor :subtrees, :balance, :value

  def initialize(value)
    @value = value
    @subtrees = [nil, nil]
    @balance = 0
  end
end
```

The most important decision in setting up these balance factors is
whether they should be bounded or unbounded. An AVL tree with bounded
balance factors guarantees that the values will only be within a
specified range. We'll look at an unbounded implementation first,
then walk through a bounded version.

### Balancing Trees: Unbounded

We will be using an unbounded balance factor of the longest path.
The root of the tree will tell you how tall the tree is, which is
useful information in and of itself. Here are the same three trees
with unbounded balance factors. Notice that the balance of each node
is the longest path in its subtrees:

```
              3,2                        5,2                5,2

          /         \                  /     \            /

      1,1             5,1          3,1         7,0    3,1

    /     \         /     \            \                  \

  0,0         2,0  4,0     6,0          4,0                4,0
```

#### Unbounded Insertion

Unbounded insertion uses the actual height of the subtree to
determine balance. As long as you know which balance factors to replace
during a rotation, the code to maintain an AVL tree's balance factors
is relatively easy to follow. Our version of unbounded insertion will
use a different implementation of `AVLTree.single_rotation!` and
`AVLTree.double_rotation!`. Instead of just performing the rotations,
`AVLTree.single_rotation!` will also handle the updating of balance
factors, then `AVLTree.double_rotation!` will call
`AVLTree.single_rotation!` twice:

```ruby
def height
  AVLTree.height!(@root)
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

   root.subtrees[other_dir] = AVLTree.single_rotation_unbounded!(root.subtrees[other_dir], other_dir)

   AVLTree.single_rotation_unbounded!(root, dir)
 end
```

 Notice that a null pointer has a height of -1 and nodes with no children
 have a height of 0. Before discussing the method behind how the balance
 factors are updated, we will walk through a simple example for single
 rotation. The following tree is an AVL tree with the new insertion of
 8 violating the AVL invariant:

```
              3,3 <----------------- No yet reached

        /            \

    1,1                5,1 <-------- Imbalance here

  /     \            /     \

0,0         2,0    4,0         6,2 <-- Source of imbalance

                                   \

                                     7,1

                                         \

                                           8,0
```

As you know from the previous discussions, a rotation will be made at 6.
Find this by subtracting the balance factor of one subtree from the
balance factor of another. If the absolute value of that subtraction is
greater than or equal to 2, an imbalance has occurred and must be remedied.
Notice how this is a direct translation of the AVL invariant, where the
difference in height between two subtrees cannot be larger than 1.
Let's now perform a single left rotation around 6 and think about how to
update the balance factors:

```
                  3,3

              /            \

          1,1                5,1

        /     \            /     \

    0,0         2,0    4,0         7,1

                                 /     \

                             6,2        8,0
```

The balance factor for 8 is still correct, but 6's is now way off, and
7's is accurate. To fix 6 we take the largest of its subtrees and add 1,
which is 0 because 6 only has null subtrees and a null subtree has a height
of -1. Then, even though 7 has an accurate height, we still check it by  
doing the same thing. The largest height in 7's subtrees is 0, adding 1
gives us 1 and the tree is correct. Move up the tree and continue to
perform the same operation all of the way back up to the root.
The resulting tree is:

```
                    3,3

              /            \

          1,1                5,2

        /     \            /     \

      0,0         2,0    4,0         7,1

                                    /     \

                                 6,0        8,0
```

This implies a very straightforward implementation for insertion.
Simply use a basic binary search tree recursive insertion, compare the
difference in heights to look for a rebalance, rebalance as necessary,
and then add 1 to the largest of the subtrees to update the balance
factors. A status flag can be used to avoid unnecessary work because we
already know that only one single or double rotation is necessary to
bring an AVL tree into balance, and the balance factors changed are
localized enough so that no further changes need to be made further up
the search path. The only thing missing from this function is the actual
code to perform a rebalance:

```ruby
def self.insert_unbounded!(root, value, done)
  return [AVLTreeNode.new(value), false] unless root

  dir = value < root.value ? 0 : 1
  other_dir = dir == 0 ? 1 : 0

  root.subtrees[dir], done = AVLTree.insert_unbounded!(root.subtrees[dir], value, done)

  unless done
    left_height = AVLTree.height!(root.subtrees[dir])
    right_height = AVLTree.height!(root.subtrees(other_dir))

    if (left_height - right_height) >= 2
      done = true
    end

    left_height = AVLTree.height!(root.subtrees[dir])
    right_height = AVLTree.height!(root.subtrees[other_dir])
    max = [left_height, right_height].max

    root.balance = max + 1
  end

  [root, done]
end

def insert_unbounded(value)
  done = false
  @root, done = AVLTree.insert!(@root, value, done)

  true
end
```

The only trick now is to figure out how to rebalance a violation of the
AVL invariant. Fortunately, we already know how to do that.
There are no longer four cases because the rotations handle updating
balance factors that always works the way we want it to. So the four cases become only two cases, those of single and double rotation. This can be generalized into a height comparison using the direction index. If the `dir` subtree is taller then a single rotation will suffice, otherwise the `other_dir` subtree is taller and a double rotation is needed. Remember the operations again and think about why this test would work (hint: if the subtrees are of equal length then there cannot be a violation):

```
dir == 1:

 3                   4

   \               /   \

     4      -->  3       5

       \

         5


 3           3                   4

   \           \               /   \

     5  -->      4      -->  3       5

   /               \

 4                   5
```

This realization paves the way for a simple solution. Just find the balance factors of the root's two subtrees. If the `dir` subtree is taller, perform a single rotation, otherwise perform a double rotation. The code to do this is short (even though it too is cleaner with temporary variables) and we can plug it into the framework given above with no trouble at all:

```ruby
def self.insert_unbounded!(root, value, done)
  return [AVLTreeNode.new(value), false] unless root

  dir = value < root.value ? 0 : 1
  other_dir = dir == 0 ? 1 : 0

  root.subtrees[dir], done = AVLTree.insert_unbounded!(root.subtrees[dir], value, done)

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

def insert_unbounded(value)
  done = false
  @root, done = AVLTree.insert!(@root, value, done)

  true
end
```

That's unbounded insertion. In theory it's simpler than bounded
insertion because there are fewer cases to consider, but the code tends
to be more verbose with the need to cleanly calculate heights and
differences. We'll find this to be the trend with deletion as well,
which we will look at next.

### Unbounded Deletion

The interesting part about unbounded deletion is that we can continue
to use the existing rotation algorithms and balance factor updates (
the tallest height incremented by 1) that were used for insertion.
Only one conceptual difference exists. Because a subtree may shrink
instead of grow, rebalancing must be performed on the opposite subtree
as the deletion was made in, just like with bounded deletion. This
means that we will be using the inverse tests for height differences.
Alternatively, we could use absolute values for both insertion and
deletion. If the new difference between subtrees is -1, the algorithm
terminates. If the new difference is -2 or less, rebalancing is
performed. Otherwise the updating of balance factors propagates up the
search path:

```ruby
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

def remove_unbounded(value)
  done = false
  @root, done = AVLTree.remove_unbounded!(@root, value, done)

  true
end
```

Let's look through a quick example to see how deletion works with a double rotation case. In the following tree, we will delete 0. After the removal of 0, a double rotation is needed, first at 69, then at 58 to restore balance completely:

```
                        58,3

                      /      \

                24,1          69,2

                /             /      \

            0,0          62,1          78,0

                             \

                               64,0
```

```
Delete 0:

        58,3

      /      \

 24,0          69,2

             /      \

        62,1          78,0

             \

               64,0
```

```
Rotate right at 69:

        58,3

      /      \

 24,0          62,2

                    \

                      69,1

                    /      \

               64,0          78,0
```

```
Rotate left at 58:

              62,2

            /      \

       58,1          69,1

     /             /      \

24,0          64,0          78,0
```

### Balancing Trees: Bounded

Our bounded range will be -2, -1, 0, +1, and +2, with -2 and +2 being
temporary values that signify a need to rebalance.

Here are the trees given previously with bounded balance factors:
```
            3,0                         5,-1                 5,-2

        /         \                   /      \             /

    1,0             5,0          3,+1          7,0    3,+1

  /     \         /     \             \                    \

0,0      2,0   4,0        6,0          4,0                  4,0
```

#### Bounded Insertion


The biggest problem with bounded insertion is that the code to correctly
update balance factors after a rotation is somewhat intricate. All in
all it's not difficult, but you have to be careful not to break the
range or give the wrong balance to nodes. Fortunately, it all falls i
nto a few simple cases and the code to implement those cases is relatively
short and easy to follow. There are four cases for insertion into an AVL
tree, one case requiring a single rotation and three cases requiring a
double rotation. Put simply, if a single rotation is needed, the tree
becomes more balanced and both the old parent and new parent are given
a value of 0. The three cases for insertion depend on the initial balance
of the lowest node that will become the new parent. The following diagram
shows these four cases (note that we're using the right path for this
example, so the direction index would be 1. Also notice that an asterisk
stands for balance factors that don't matter during intermediate rotations):

```
Single case:


     x,+2                         y,0

   /      \                     /     \

 A          y,+1     ->     x,0         C

          /      \        /     \

        B          C    A         B

```

```
Double case 1 (z is balanced):


     x,+2                   x,*                               z,0

   /      \               /     \                          /       \

 A          y,-1        A         z,*                  x,0           y,0

          /      \   ->         /     \         ->   /     \       /     \

      z,0          D          B         y,*        A         B   C         D

    /     \                           /     \

  B         C                       C         D
```

```
Double case 2 (z's right subtree is taller):


     x,+2                   x,*                               z,0

   /      \               /     \                          /       \

 A          y,-1        A         z,*                  x,-1          y,0

          /      \   ->         /     \         ->   /      \      /     \

      z,+1         D          B         y,*        A          B  C         D

    /      \                          /     \

  B          C                      C         D

```

```
Double case 3 (z's left subtree is taller):


     x,+2                   x,*                               z,0

   /      \               /     \                          /       \

 A          y,-1        A         z,*                  x,0          y,+1

          /      \   ->         /     \         ->   /     \      /      \

      z,-1         D          B         y,*        A         B  C          D

    /      \                          /     \

  B          C                      C         D
```

The code to implement this is simple, and can be modularized into a
function. The best part is that the function can be reused for deletion
as well because deletion has three similar cases for double rotations.
There is a trick to this code, by the way. Instead of using -1 and +1
directly, we will use the value of the direction index to determine
which would be best suited for the current direction, thus removing an
unnecessary symmetric case. This balance information varies with insertion
and deletion, just like the direction index, so they are both arguments
to the function. Follow the code closely and walk through each of the
cases above to see how the diagrams translate into code:

```ruby
def self.adjust_balance!(root, dir, bal)
  other_dir = dir == 0 ? 1 : 0

  n = root.subtrees[dir]
  nn = n.subtrees[other_dir]

  if nn.balance == 0
    root.balance = 0
    n.balance = 0
  elsif nn.balance == bal
    root.balance = -bal
    n.balance = 0
  else
    root.balance = 0
    n.balance = bal
  end

  nn.balance = 0
end
```

Of course, just knowing how to change the balance factors for a double
rotation isn't enough. Another helper function that handles rebalancing
for insertion must be used that actually performs the rotations and also
fixes the balance factors for a single rotation. Remember that there are
only two rotation cases, and `AVLTree.adjust_balance!` fixes the balance
factors for the double rotation case. So the code for
`AVLTree.insert_balance!` is short and sweet. This is the function that
determines the value of `bal` and calls the rotation functions as
necessary. Once again, follow through this code and see how it compares
to each diagram above:

```ruby
def self.insert_balance!(root, dir)
  other_dir = dir == 0 ? 1 : 0

  n = root.subtrees[dir]
  bal = dir == 0 ? -1 : +1

  if n.balance == bal
    root.balance = 0
    n.balance = 0
    root = AVLTree.single_rotation!(root, other_dir)
  else
    AVLTree.adjust_balance!(root, dir, bal)
    root = AVLTree.double_rotation!(root, other_dir)
  end

  root
end
```

These two functions are all that's needed to rebalance a violation of the AVL invariant during insertion. Now all we need to do is come up with the framework to insert a new node and update the balance factors. The good news is that from the parent of the newly inserted node, updating a balance factor is a simple matter of incrementing the balance factor if we went down the right subtree or decrementing the balance factor if we went down the left subtree. Beyond that it's just a basic insertion. However, during AVL insertion, only one call of `AVLTree.insert_balance!` will ever be needed, and changing the balance factors above that part of the tree will break the data structure. So we need a way to stop updating after a rebalance has been performed. In an iterative version, this is a simple matter of breaking from a loop or returning from a function, but in the following recursive version a status flag is needed:

```ruby
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

def insert(value)
  done = false
  @root, done = AVLTree.insert!(@root, value, done)

  true
end
```

There are only three cases for updating balance factors, since there are only three values in the range. If the balance factor was 0, then it is incremented or decremented and the updating continues up the tree. If the balance factor was -1 or +1 and becomes 0, the tree has become more balanced and no more updating or rebalancing is required. If the balance factor was -1 or +1 and becomes -2 or +2, rebalancing is required and `AVLTree.insert_balance!` is called. After `AVLTree.insert_balance!`, the tree is once again balanced and no more updating is performed. The code is simple, but it is still recommended to draw out several tree insertions while following the algorithm closely to understand what is going on. Let's walk through a degenerate case to see that the AVL tree results in a well balanced tree. The degenerate case is an ascending sequence of integers, 0 through 9. Keep in mind that newly inserted nodes have subtrees of equal height (i.e. two empty subtrees), so the balance factor of a node returned by the constructor of `AVLTreeNode` is 0 to show that it is balanced:

```
Insert 0:

   0,0
```

```
Insert 1:

   0,1

       \

         1,0
```

```
Insert 2:

       1,0

     /     \

 0,0         2,0
```

```
Insert 3:

       1,1

     /     \

 0,0         2,1

                 \

                   3,0
```

```
Insert 4:

       1,1

     /     \

 0,0         3,0

           /     \

       2,0         4,0
```

```
Insert 5:

             3,0

           /     \

       1,0         4,1

     /     \           \

 0,0         2,0         5,0
```

```
Insert 6:

                 3,0

           /            \

       1,0                5,0

     /     \            /     \

 0,0         2,0    4,0         6,0
```

```
Insert 7:

                 3,1

           /            \

       1,0                5,1

     /     \            /     \

 0,0         2,0    4,0         6,1

                                    \

                                      7,0
```

```
Insert 8:

                 3,1

           /            \

       1,0                5,1

     /     \            /     \

 0,0         2,0    4,0         7,0

                              /     \

                          6,0         8,0
```

```
Insert 9:

                   3,1

           /                \

       1,0                    7,0

     /     \                /     \

 0,0         2,0        5,0         8,1

                      /     \           \

                  4,0         6,0         9,0
```

#### Bounded Deletion

Deletion from an AVL tree is only marginally more complicated than insertion. This is shocking to most people because deletion is always left as an exercise to the reader, but not before scaring the wits out of the reader by talking about how long and complicated it is and that the algorithms are beyond the scope of a textbook or paper devoted to the topic. In reality, there is only one extra case for rebalancing in AVL deletion, and that is a simple single rotation case. The extra complexity comes from the task of removing a node from the tree rather than any rebalancing effort. The five cases are as follows:

```
Single case 1 (y is not balanced):


     x,+1                         y,0

   /      \                     /     \

 A          y,+1     ->     x,0         C

          /      \        /     \

        B          C    A         B

```

```
Single case 2 (y is balanced):


     x,+1                         y,-1

   /      \                     /      \

 A          y,0     ->     x,+1          C

          /     \        /      \

        B         C    A          B

```

```
Double case 1 (z is balanced):


     x,+1                   x,*                               z,0

   /      \               /     \                          /       \

 A          y,-1        A         z,*                  x,0           y,0

          /      \   ->         /     \         ->   /     \       /     \

      z,0          D          B         y,*        A         B   C         D

    /     \                           /     \

  B         C                       C         D

```

```
Double case 2 (z's right subtree is taller):


     x,+1                   x,*                                z,0

   /      \               /     \                           /       \

 A          y,-1        A         z,*                  x,-1           y,0

          /      \   ->         /     \         ->   /      \       /     \

      z,+1         D          B         y,*        A          B   C         D

    /      \                          /     \

  B          C                      C         D
```

```
Double case 2 (z's left subtree is taller):


     x,+1                   x,*                               z,0

   /      \               /     \                          /       \

 A          y,-1        A         z,*                  x,0           y,+1

          /      \   ->         /     \         ->   /     \       /      \

      z,-1         D          B         y,*        A         B   C          D

    /      \                          /     \

  B          C                      C         D
```

Amazingly enough, all but one of those cases are solved problems from insertion. So the code to add the extra case and rebalance after a deletion is trivial:

```ruby
def self.remove_balance!(root, dir, done)
  other_dir = dir == 0 ? 1 : 0

  n = root.subtrees[other_dir]
  bal = dir == 0 ? -1 : 1

  if n.balance == -bal
    root.balance = 0
    n.balance = 0
    root = AVLTree.single_rotation!(root, dir)
  elsif n.balance == bal
    AVLTree.adjust_balance!(root, other_dir, -bal)
    root = AVLTree.double_rotation!(root, dir)
  else
    root.balance = -bal
    n.balance = bal
    root = AVLTree.single_rotation!(root, dir)
    done = true
  end

  [root, done]
end
```

Wait, why does the new case set the status flag to show that rebalancing is finished? Unlike insertion, an AVL deletion could potentially require rebalancing all of the way back up the tree, so there are fewer cases where the updating terminates early and this is one of them. In the new case, the height of the tree doesn't change, so there is no need to continue rebalancing up the tree. An important key to how deletion works is to remember that instead of rebalancing the subtree that was increased after an insertion, we need to rebalance the opposite subtree that the node is deleted from. So look very closely at the values of `dir` and `bal` when `AVLTree.remove_balance!` is called from the following AVL deletion algorithm:

```ruby
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
    root.subtrees[dir], done = AVLTree.remove!(root.subtrees[dir], value, done)

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

def remove(value)
  done = false
  @root, done = AVLTree.remove!(@root, value, done)

  true
end
```

The code to rebalance is actually shorter than insertion because of fewer cases where the updating would terminate early. What makes this code longer is the extra work of deleting a node. The idea behind the recursive deletion is to search for the node to delete. Then once this node is found, if it has only one child or no children, simply replace the node with its child. If the node has two children, the inorder predecessor is found and its data is copied into the node to be deleted. This is where the tricky part comes in. Instead of stopping the recursion and trying to remove the inorder predecessor, the recursion continues by replacing the search key with the value of the inorder predecessor. This is somewhat confusing because the search key changes in the middle of the recursive path. But this walkthrough is about AVL trees, not the variations of binary search tree deletion, so it is highly recommend that we can work through this function to get a feel for how it works.

Let's walk through the deletion of items from an existing AVL tree. This execution will continue what was started with insertion by tracing through the deletion of a degenerate case, 0 through 7:

```
Remove 0:

             3,1

     /                \

 1,1                    7,0

     \                /     \

       2,0        5,0         8,1

                /     \           \

            4,0         6,0         9,0
```

```
Remove 1:

             7,-1

           /      \

       3,1          8,1

     /     \            \

 2,0         5,0          9,0

           /     \

       4,0         6,0
```

```
Remove 2:

              7,-1

            /      \

       5,-1          8,1

     /      \            \

 3,1          6,0          9,0

     \

       4,0
```

```
Remove 3:

             7,0

           /     \

       5,0         8,1

     /     \           \

 4,0         6,0         9,0
```

```
Remove 4:

       7,0

     /     \

 5,1         8,1

     \           \

       6,0         9,0
```

```
Remove 5:

       7,1

     /     \

 6,0         8,1

                 \

                   9,0

```

```
Remove 6:

       8,0

     /     \

 7,0         9,0

```

```
Remove 7:

 8,1

     \

       9,0

```

### Conclusion

That's it! We're all done with our AVL tree project. Now, let's go over some general information about the performance properties and a few parting words.

AVL trees are about as close to optimal as balanced binary search trees can get without eating up resources. We are rest assured that the O(log N) performance of binary search trees is guaranteed with AVL trees, but the extra bookkeeping required to maintain an AVL tree can be prohibitive, especially if deletions are common. Insertion into an AVL tree only requires one single or double rotation, but deletion could perform up to O(log N) rotations, as in the example of a worst case AVL (i.e. Fibonacci) tree. However, those cases are rare, and still very fast.

AVL trees are best used when degenerate sequences are common, and there is little or no locality of reference in nodes. That basically means that searches are fairly random. If degenerate sequences are not common, but still possible, and searches are random then a less rigid balanced tree such as red black trees or Andersson trees are a better solution. If there is a significant amount of locality to searches, such as a small cluster of commonly searched items, a splay tree is theoretically better than all of the balanced trees because of its move-to-front design.

The sad reality is that an AVL tree is a complicated data structure that is very fragile in practice. Unfortunately, both of these conspire to keep it from being quickly considered in the real world, and implementations will usually only come from students. Hopefully this project helped you to understand the ideas behind AVL trees as well as potential implementation methods. In reality it's not terribly difficult to write a good AVL tree, but it does take a good understanding of how they work and an attention to detail.
