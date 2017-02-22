# cycle-alt-keys
Easy access to symbols not on your keyboard

# Usage

Execute `cycle_alt_keys.exe.` Make sure that you have `definitions/` in the same directory.

A *base key* is any key you can type. A *cycle key* is used to access the *alternative keys* based on a base key. The default cycle key is `` ` ``, and the alternative keys it's associated with are defined in `definitions/math.txt`.

Example: using `math.txt`, pressing `` ` `` right after typing `e` - the base key - changes the `e` to `ε` (epsilon), an alternative key of `e`. Pressing `` ` `` one more time gives you `∈` (element of), another alt key, and pressing `` ` `` once more brings you back to `e`.

# Modifying cycle & alt keys

You can define your own set of cycle & alt keys by making tab-delimited rows of base keys followed by your desired alt key(s), ending with the row `CYCLE_KEY your_cycle_key` to associate the previous definitions to a `your_cycle_key`.

For example, `math.txt` contains the following defintions

~~~~
a α
b β
.
.
.
e ε ∈
.
.
.
z ℤ
CYCLE_KEY `
~~~~

(The base keys do not have to be in alphabetical order).

To switch to another definition simply press Ctrl+Shift+CycleKey, where CycleKey represents any currently defined cycle key.
