

## 运行环境

- Linux(like ubuntu) 
- python3.10+
- clang

## 安装依赖库
```
$ pip install -r ./requirements.txt
```

## 编译yian代码

使用下来命令进行编译
```
$ ./scripts/yian_compiler.py <文件或者目录路径>
```

也可以添加优化等级设置（-o0, -o1, -o2, -o3, or -os），例如
```
$ ./scripts/yian_compiler.py -o2 tests/core_function/test1.an
```
