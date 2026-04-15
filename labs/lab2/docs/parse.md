# 语法分析实验说明（Parse）

## 1. 实验目标

本实验要求你基于给定模板实现一个语法分析器（Parser），将词法分析器（Lexer）输出的 Token 流转换为抽象语法树（AST）。通过本实验，你将掌握：

- 如何设计和实现一个语法分析器来处理复杂的语言结构。
- 如何使用 `Pratt Parse` 算法在递归下降解析器中处理表达式的优先级和结合性。

## 2. 实验环境

同 Lab 1

## 3. 代码介绍

### 3.1 目录与文件

- 实验代码：`labs/lab2/parse/parser.an`
- 测试输入：`labs/lab2/test_cases/01.an ~ 06.an`
- 参考答案：`labs/lab2/test_results/01.txt ~ 06.txt`

### 3.2 主流程

核心流程如下：

1. `parser_main::main()` 读取测试输入文件。
2. `parser.an::Parser::parse()` 使用递归下降解析器实现语法分析。
3. 最终写入输出文件（`labs/lab2/output/xx.txt`）。

### 3.3 数据结构

`ast.an` 和 `expr.an` 定义了抽象语法树的结构，包括各种表达式、语句、函数定义等。节点类型汇总如下:

- `Program`: 整个程序
- `FuncDef`: 函数定义
- `StructDef`: 结构体定义
- `EnumDef`: 枚举定义
- `Stmt`: 语句节点, 有以下类型:
  - `VarDecl`: 变量声明
  - `ExprStmt`: 表达式语句
  - `Delete`: 指针释放语句
  - `Return`: 返回语句
  - `If`: 条件语句
  - `While`: 循环语句
  - `Loop`: 无限循环语句
  - `For`: for 循环语句
  - `Match`: 模式匹配语句
  - `Break`: break 语句
  - `Continue`: continue 语句
- `Expr`: 表达式节点, 有以下类型:
  - `Lit`: 字面量表达式
  - `Ident`: 标识符表达式, 可能是变量名或函数名或类型名
  - `Call`: 函数调用表达式
  - `FieldAccess`: 字段访问表达式
  - `Binary`: 二元运算表达式
  - `Unary`: 一元运算表达式
  - `Dyn`: 内存申请表达式

几个说明:

1. 赋值(`=`)以及复合赋值(`+=`, `-=`, `*=`等)被视为常规的二元运算, 因此不存在所谓的赋值语句, 只有表达式语句(`ExprStmt`)。
2. 表达式中的标识符(`Ident`)既可以是变量名, 也可以是函数名, 还可以是类型名(如结构体或枚举), 在后续的语义分析阶段确定。
3. 字段访问(`FieldAccess`)有两种可能: 结构体字段访问(`a.b`)和枚举成员访问(`Color.Red`), 在后续的语义分析阶段确定。
4. 函数调用(`Call`)也有两种可能: 函数调用(`foo(x, y)`)和结构体构造(`Point(1, 2)`), 在后续的语义分析阶段确定。
5. `Match` 中的 `Pattern` 可以是整数、字符、枚举的成员、Wildcard(`_`), 具体参见相关数据结构定义。
6. 为了**简化语法解析的实现**, 我们对一些语法进行了修改:
   1. 所有语句都必须以分号结尾, 如同 C/C++/Java 等语言一样
   2. 变量声明必须显式使用 `let` 关键字, 如 `let x: i32 = 10;`

### 3.4 算法思路

语法分析器的核心是 `Parser::parse()` 方法, 其主要流程如下:

1. 源代码顶层结构为一系列函数定义、结构体定义、枚举定义
2. `parse()` 通过循环不断读取 Token, 根据 Token 类型决定解析函数:
   - `struct` -> `parse_struct_def()`
   - `enum` -> `parse_enum_def()`
   - 其他 -> `parse_func_def()`
3. 递归调用这些解析函数, 逐步构建整个程序的 AST 节点。

最复杂的部分是表达式解析, 需要使用 `Pratt Parse` 算法来处理不同运算符的优先级和结合性

### 3.5 Pratt Parse 算法

`Pratt Parse` 是一种高效的表达式解析算法, 其核心思想是为每个中缀运算符定义左右两个优先级, 通过这种方式, 正确处理不同运算符的结合性和优先级关系。

#### 优先级与结合性

运算符的优先级决定了在没有括号的情况下, 哪些运算先被解析。而结合性则决定了当多个相同优先级的运算符连续出现时, 解析的方向（从左到右或从右到左）。

例如:

- `*` 的优先级高于 `+`, 因此 `1 + 2 * 3` 解析为 `1 + (2 * 3)`
- `=` 是右结合的, 因此 `a = b = c` 解析为 `a = (b = c)`

本次实验中, 所有运算符的优先级和结合性都已经通过预先定义好的左/右优先级给出, 详见 `expr.an`.

#### 算法流程

这一部分与 `parser.an` 中的四个函数一一对应:

- `parse_expr_bp(min_bp)`：处理中缀运算符优先级与结合性的核心循环。
- `parse_prefix_expr()`：处理前缀一元运算和特殊前缀（如 `dyn`、`true`、`false`）。
- `parse_primary_expr()`：处理原子表达式（标识符、字面量、括号表达式、数组字面量）。
- `parse_postfix_expr(expr)`：在已有表达式后继续吸收后缀（调用、字段访问、下标）。

为便于理解，先明确几个关键概念。

##### 关键概念 1：`min_bp`（最小绑定力阈值）

`min_bp` 可以理解为“当前这一层调用愿意接收的最低中缀优先级”。

- 当看到某个中缀运算符时，如果它的 `left_bp < min_bp`，说明它优先级不够，不能在当前层处理，必须交给外层调用。
- 如果 `left_bp >= min_bp`，当前层可以消费该运算符，并继续解析右侧表达式。

这个机制是 Pratt Parse 控制优先级的核心。

##### 关键概念 2：`left_bp` 与 `right_bp`

每个中缀运算符都预先定义一对绑定力：`(left_bp, right_bp)`。

- `left_bp` 决定“当前运算符是否能在这一层被接收”。
- `right_bp` 决定“递归解析右操作数时，右侧还能吸收哪些运算符”。

通过左右绑定力不完全相同，可以表达结合性：

- 左结合运算符（如 `+`、`*`）通常让下一层更难继续吃同级左侧结构。
- 右结合运算符（如赋值 `=`）会让右侧继续吸收同级运算符，因此 `a = b = c` 解析成 `a = (b = c)`。

##### 关键概念 3：前缀、主表达式、后缀三层分工

- 前缀层（`parse_prefix_expr`）负责识别表达式的起点形态，例如 `-x`、`*p`、`not flag`。
- 主表达式层（`parse_primary_expr`）负责最原子的表达式单元，例如 `x`、`123`、`(a+b)`、`[1,2,3]`。
- 后缀层（`parse_postfix_expr`）负责把原子表达式继续扩展成链式结构，例如 `a(c)[i].b`。

##### 关键概念 4：循环“吸收”

`parse_expr_bp` 与 `parse_postfix_expr` 都采用 `loop` 连续吸收 token：

- 能继续组成合法表达式就持续消耗 token 并构建 AST
- 一旦不满足条件就立即 `break`，把控制权交回上层。

##### 具体执行步骤

1. 外部入口 `parse_expr()` 调用 `parse_expr_bp(1)`，表示从最低门槛开始解析一个完整表达式。
2. `parse_expr_bp` 首先调用 `parse_prefix_expr()`，拿到左侧表达式 `left`。
3. `parse_prefix_expr`：
  - 如果当前是前缀运算符（`-`、`*`、`&`、`~`、`not`），消费运算符并以较高绑定力递归解析操作数。
  - 如果当前是 `dyn`，解析类型与可选大小。
  - 如果是 `true/false`，直接返回布尔字面量。
  - 否则转入 `parse_primary_expr` + `parse_postfix_expr`。
4. `parse_primary_expr` 解析表达式原子：标识符、字面量、括号表达式、数组字面量。
5. `parse_postfix_expr` 在已有 `expr` 上循环吸收后缀：
  - `(...)` 调用
  - `.field` 字段访问
  - `[index]` 下标访问
6. 回到 `parse_expr_bp` 的中缀循环：
  - 看下一个 token 是否是中缀运算符；
  - 检查 `left_bp` 是否满足当前 `min_bp`；
  - 若满足，消费运算符并递归解析右侧 `right = parse_expr_bp(right_bp)`；
  - 合成 `left = Binary(left, op, right)`，继续下一轮。
7. 当中缀循环无法继续时，返回 `left`，完成本层表达式构建。

#### 解析过程实例

以下示例展示优先级、前后缀链、递归边界如何协同工作。

示例表达式1: `a = b = c`

1. `parse_expr()` 会直接调用 `parse_expr_bp(1)`。此次调用记为 `C1`。
2. `C1` 调用 `parse_prefix_expr()` 解析出 `left` 为 `Ident("a")`。
3. `C1` 进入中缀循环，看到 `=`，其绑定力为 `(1, 1)`，满足 `left_bp >= min_bp`，消费 `=` 并递归调用 `parse_expr_bp(1)` 解析右侧。此次调用记为 `C2`。
4. `C2` 调用 `parse_prefix_expr()` 解析出 `left` 为 `Ident("b")`。
5. `C2` 进入中缀循环，看到 `=`，其绑定力为 `(1, 1)`，满足 `left_bp >= min_bp`，消费 `=` 并递归调用 `parse_expr_bp(1)` 解析右侧。此次调用记为 `C3`。
6. `C3` 调用 `parse_prefix_expr()` 解析出 `left` 为 `Ident("c")`。
7. `C3` 进入中缀循环，看到没有更多运算符，直接返回 `Ident("c")`。
8. 从 `C3` 返回到 `C2` 后，`C2` 构建 `Binary(Ident("b"), "=", Ident("c"))` 并继续中缀循环，但没有更多运算符，返回该表达式。
    ```text
    Binary: =
    |-- Ident("b")
    `-- Ident("c")
    ```
9.  从 `C2` 返回到 `C1` 后，`C1` 构建 `Binary(Ident("a"), "=", Binary(Ident("b"), "=", Ident("c")))` 并继续中缀循环，但没有更多运算符，返回该表达式。
    ```text
    Binary: =
    |-- Ident("a")
    `-- Binary: =
        |-- Ident("b")
        `-- Ident("c")
    ```
10. 解析结束

示例表达式2: `-a * b + c`

1. `parse_expr()` 调用 `parse_expr_bp(1)`，记为 `C1`。
2. `C1` 调用 `parse_prefix_expr()` 解析出 `left` 为 `Unary("-", Ident("a"))`。
   ```text
   Unary: -
   `-- Ident("a")
   ```
3. `C1` 进入中缀循环，看到 `*`，其绑定力为 `(11, 12)`，满足 `left_bp >= min_bp`，消费 `*` 并递归调用 `parse_expr_bp(12)` 解析右侧。此次调用记为 `C2`。
4. `C2` 调用 `parse_prefix_expr()` 解析出 `left` 为 `Ident("b")`。
5. `C2` 进入中缀循环，看到 `+`，其绑定力为 `(10, 11)`，不满足 `left_bp >= min_bp`（因为 `10 < 12`），因此 `C2` 直接返回 `Ident("b")`。
6. 从 `C2` 返回到 `C1` 后，`C1` 构建 `Binary(Unary("-", Ident("a")), "*", Ident("b"))` 将其作为新的 `left`。
   ```text
   Binary: *
   |-- Unary: -
   |   `-- Ident("a")
   `-- Ident("b")
   ```
7. `C1` 继续中缀循环，看到 `+`，其绑定力为 `(10, 11)`，满足 `left_bp >= min_bp`（因为 `10 >= 1`），消费 `+` 并递归调用 `parse_expr_bp(11)` 解析右侧。此次调用记为 `C3`。
8. `C3` 调用 `parse_prefix_expr()` 解析出 `left` 为 `Ident("c")`。
9.  `C3` 进入中缀循环，没有更多运算符，直接返回 `Ident("c")`。
10. 从 `C3` 返回到 `C1` 后，`C1` 构建 `Binary(Binary(Unary("-", Ident("a")), "*", Ident("b")), "+", Ident("c"))` 将其作为新的 `left`。
    ```text
    Binary: +
    |-- Binary: *
    |   |-- Unary: -
    |   |   `-- Ident("a")
    |   `-- Ident("b")
    `-- Ident("c")
    ```
11. `C1` 继续中缀循环，没有更多运算符，直接返回该表达式。
12. 解析结束

示例表达式3: `1 + 2 == 3 and 4 > 5`

1. `parse_expr()` 调用 `parse_expr_bp(1)`，记为 `C1`。
2. `C1` 调用 `parse_prefix_expr()` 解析出 `left` 为 `Lit(Int(1))`。
3. `C1` 进入中缀循环，看到 `+`，其绑定力为 `(10, 11)`，满足 `left_bp >= min_bp`，消费 `+` 并递归调用 `parse_expr_bp(11)` 解析右侧。此次调用记为 `C2`。
4. `C2` 调用 `parse_prefix_expr()` 解析出 `left` 为 `Lit(Int(2))`。
5. `C2` 进入中缀循环，看到 `==`，其绑定力为 `(7, 8)`，不满足 `left_bp >= min_bp`（因为 `7 < 11`），因此 `C2` 直接返回 `Lit(Int(2))`。
6. 从 `C2` 返回到 `C1` 后，`C1` 构建 `Binary(Lit(Int(1)), "+", Lit(Int(2)))` 将其作为新的 `left`。
   ```text
   Binary: +
   |-- Lit(Int(1))
   `-- Lit(Int(2))
   ```
7. `C1` 继续中缀循环，看到 `==`，其绑定力为 `(7, 8)`，满足 `left_bp >= min_bp`（因为 `7 >= 1`），消费 `==` 并递归调用 `parse_expr_bp(8)` 解析右侧。此次调用记为 `C3`。
8. `C3` 调用 `parse_prefix_expr()` 解析出 `left` 为 `Lit(Int(3))`。
9.  `C3` 进入中缀循环，看到 `and`，其绑定力为 `(3, 4)`，不满足 `left_bp >= min_bp`（因为 `3 < 8`），因此 `C3` 直接返回 `Lit(Int(3))`。
10. 从 `C3` 返回到 `C1` 后，`C1` 构建 `Binary(Binary(Lit(Int(1)), "+", Lit(Int(2)), "==", Lit(Int(3)))` 将其作为新的 `left`。
    ```text
    Binary: ==
    |-- Binary: +
    |   |-- Lit(Int(1))
    |   `-- Lit(Int(2))
    `-- Lit(Int(3))
    ```
11. `C1` 继续中缀循环，看到 `and`，其绑定力为 `(3, 4)`，满足 `left_bp >= min_bp`（因为 `3 >= 1`），消费 `and` 并递归调用 `parse_expr_bp(4)` 解析右侧。此次调用记为 `C4`。
12. `C4` 调用 `parse_prefix_expr()` 解析出 `left` 为 `Lit(Int(4))`。
13. `C4` 进入中缀循环，看到 `>`，其绑定力为 `(8, 9)`，满足 `left_bp >= min_bp`（因为 `8 >= 4`），消费 `>` 并递归调用 `parse_expr_bp(9)` 解析右侧。此次调用记为 `C5`。
14. `C5` 调用 `parse_prefix_expr()` 解析出 `left` 为 `Lit(Int(5))`。
15. `C5` 进入中缀循环，没有更多运算符，直接返回 `Lit(Int(5))`。
16. 从 `C5` 返回到 `C4` 后，`C4` 构建 `Binary(Lit(Int(4)), ">", Lit(Int(5))` 将其作为新的 `left`。
    ```text
    Binary: >
    |-- Lit(Int(4))
    `-- Lit(Int(5))
    ```
17. `C4` 继续中缀循环，没有更多运算符，直接返回 `Binary(Lit(Int(4)), ">", Lit(Int(5))`。
18. 从 `C4` 返回到 `C1` 后，`C1` 构建 `Binary(Binary(Lit(Int(1)), "+", Lit(Int(2)), "==", Lit(Int(3))), "and", Binary(Lit(Int(4)), ">", Lit(Int(5)))` 将其作为新的 `left`。
    ```text
    Binary: and
    |-- Binary: ==
    |   |-- Binary: +
    |   |   |-- Lit(Int(1))
    |   |   `-- Lit(Int(2))
    |   `-- Lit(Int(3))
    `-- Binary: >
        |-- Lit(Int(4))
        `-- Lit(Int(5))
    ```
19. `C1` 继续中缀循环，没有更多运算符，直接返回该表达式。
20. 解析结束

在自行推演上述示例时，建议画出表达式树, 并记录每一步的调用栈, 以更清晰地理解算法的执行流程和优先级控制机制。

### 3.6 需要补全的 TODO

- `parse_enum_def`: 解析枚举类型定义的函数
- `parse_var_decl`: 解析变量声明的函数
- `parse_for`: 解析 for 循环的函数
- `Pratt Parse` 相关:
  - `parse_expr_bp` 表达式解析主算法
  - `parse_prefix_expr` 前缀表达式解析
  - `parse_primary_expr` 主表达式解析
  - `parse_postfix_expr` 后缀表达式解析

### 3.7 测试

你可以通过下面的方式测试你的语法分析器：

1. 修改 `labs/lab2/parse/parser_main.an` 中所包含的测试名(你也可以构造自己的测试)
2. 命令行执行: `scripts/yian_compiler.py labs/lab2/parse`
3. 执行生成的可执行文件, 将会在 `labs/lab2/output/` 目录下生成对应的输出文件, 与 `labs/lab2/test_results/` 中的参考输出进行对比。
4. 因为一些神秘小 BUG, 你需要自己创建 `labs/lab2/output/` 目录, 否则输出文件无法生成。

---

## 4. 实验要求

### 4.1 功能要求

至少满足以下能力：

- 正确解析函数定义、结构体定义、枚举定义。
- 正确解析变量声明、表达式语句、条件语句、循环语句、模式匹配语句等。
- 正确解析各种表达式，包括字面量、标识符、函数调用、字段访问、二元运算、一元运算等。
- 正确处理运算符优先级和结合性。
- 输出正确的 AST 结构。

### 4.2 输出要求

- 输出头部保留：`=== Parser Output ===`
- 输出为树形结构

### 4.3 提交要求

提交内容：

- 你的 `labs/lab2/parse/parser.an`
- 实验报告(可选)
  - 可以包含你对 Pratt Parse 算法的理解
  - 可以包含你在实现过程中遇到的挑战和解决方案
  - 可以包含你对实验设计的任何反馈和建议
  - 你的分数完全由测试结果决定, 不交实验报告或者报告写的不好不会扣分, 写得好也不会加分

---

## 5. 测试与评测规则

你将拿到 `01-06` 号测试及其答案，评分时 `07-10` 号测试作为隐藏评测使用。

### 5.1 公开测试

- 输入：`labs/lab2/test_cases/01.an` ~ `labs/lab2/test_cases/06.an`
- 参考答案：`labs/lab2/test_results/01.txt` ~ `labs/lab2/test_results/06.txt`

### 5.2 隐藏测试（用于评分）

- 输入：`labs/lab2/test_cases/07.an` ~ `labs/lab2/test_cases/10.an` (未包含在公开资料中)
- 参考答案不公开。

---

## 6. 评分标准（100 分）

- 公开测试 01-06：每题 10 分，共 60 分
- 隐藏测试 07-10：每题 10 分，共 40 分
- 评分依据：输出与标准答案逐行一致（允许末尾空行差异由评测脚本统一处理）

---

## 8. 学术诚信

- 禁止抄袭。
- 可以使用 AI 辅助工具，但你最好知道自己的代码在做什么。
