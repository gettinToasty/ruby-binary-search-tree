# Binary Search Trees

## Basic Binary Search Tree

<!-- TODO: make all images pretty illustrator images -->

We are going to implement a basic Binary Search Tree.

Start off by implementing `BSTNode`. The node will take in a value. Because we are creating a Binary Search Tree, each node should also store a left node and a right node. The left and right nodes will initially be nil.

Next, let's implement `BinarySearchTree`. Remember: lesser or equal nodes to the left of their parents, larger nodes to the right.

We'll be writing instance methods that call recursive class methods.

Write the following pairs of methods:

### Methods

#### `#initialize`
  Should just store a root node. Start this as nil.

#### `::insert` and `::insert!`
##### `::insert`
  The instance method should take in a value to insert into the BinarySearchTree. If the tree's root is nil, `::insert` should create a new node and assign it to the root. If the tree's root is not nil, `::insert` should call `::insert!` with the tree's root and the given value to be inserted.

######`::insert!`
  The class method should accept the value to be inserted and a current node (originally the root). It will recursively call the left or right node of the current node, depending on whether the value is smaller or larger than the current node's value respectively.

#### `::min` and `::max`
These methods should take in a node and return the min and max nodes respectively of the nodes and all their children. If there is no node passed in, the methods should return nil.

##### Instance Methods
  The `::min` and `::max` instance methods should pass the tree's root to the corresponding `::min` and `::max` class methods.

##### Class Methods
  The `::min` and `::max` class methods should receive a current node and recursively call its left node (if `::min`) or right node (if `::max`).

#### `::find` and `::find!`
  The instance method `::find` should take in a value. It passes that value and the tree's root to the class method `::find!`.

  The class method `::find!` takes in a root node and a value to search for. It should recursively call itself until it finds the node that it is searching for (in which case it returns the sought out node), or runs out of nodes to search (in which case it returns nil). What is the time complexity of `::find!` in our BST?

#### `::height!` and `::height!`
  The instance method `::height` passes the tree's root to the class method `::height!`. If no node is passed in, `::height!` returns -1. Otherwise, `::height!` makes a recursive call to itself on the node's left and right children and returns the deeper depth.

#### `::delete_min!`
  This class method takes in a parent node. The goal here is to delete the node with the minimum value of that node and its children. We will do this by making recursive call to `::delete_min!` on the node's left child.

  ```
            A                       A
          /   \                   /   \
        B       C               B       C
      /   \            =>     /   \     
    D      E                F      E
      \
        F
  ```

  Eventually, when the node passed in has no more left nodes (D), we have found the minimum. What do we need to do? We need to replace D with D's right child, F.

#### `::delete` and `::delete!`
##### `::delete`
  The instance method `::delete` should pass the value to be deleted and the root node to the class method `::delete!`. It should also reassign the tree's root to the result of calling the class method (this will be the root of the updated tree).

##### `::delete!`
  The `::delete!` class method takes in a node and a value to delete. It will recursively search the node and its left or right children, depending on whether the value is less than or greater than the parent node respectively. When it finds the correct node, it will remove it from the tree.

  Hint 0: Remove the target node by excluding it from the tree.
  Hint 1: Think about the different cases that could result from excluding the target node. You will use the class method `::delete_min!`for one of them.

#### `::inorder` and `::inorder!`
  The instance method `::inorder` should call the class method `::inorder!` with the tree's root.
  The class method `::inorder!` should take in a node and return an array of it and all its children in order. If there are no nodes, it should return an empty array.

#### `::preorder` and `::preorder!`
  The instance method `::preorder` should call the class method `::preorder!` with the tree's root.
  The class should take in a node. It should return an array of values with the order a) the node, b) the node's left children, then finally c) the node's right children. It should return an empty array if there are no nodes.

#### `::postorder` and `::postorder!`
  The instance method `::postorder` should call the class method `::postorder!` with the tree's root.
  This method should take in a node. It should return an array of values with the order a) the node's left children, b) the node's right children, then finally c) then node itself. It should return an empty array if there are no nodes.

Now you have a BST! Before moving on to Part 2, let's consider an important limitation of Binary Search Trees.

### Degenerate Trees

Basic Binary Search Trees can degenerate into linear data structures in 3 cases.
  * The data is inserted in ascending sorted order
  * The data is inserted in descending sorted order
    * This results in trees with nothing but left or right links!
  * The data is inserted in alternating order from the outside in.
    * Same degenerate case arises because there is only one choice at each node and the effect is a linear data structure.

```
 0                                  3          0

   \                              /              \

     1                          2                  3

       \          or          /          or      /

         2                  1                  1

           \              /                      \

             3          0                          2
```

This is basically an inefficient linked list because the binary search tree algorithms expect each node to have two paths rather than one, whereas linked list algorithms are written with a linear structure in mind. The result is a linear data structure that has expensive algorithms. What we want in a binary search tree is a broad and flat structure, where each node has two links and any path is logarithmic to the number of nodes in the tree:

```
          3

      /       \

    1           5

  /   \       /   \

0       2   4       6
```

We'll ensure this structure in Part 2 by implementing an AVL Tree.

[Continue on to Part 2: AVL Trees](./avl.md)
