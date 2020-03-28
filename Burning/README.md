# 燃烧效果
## 基本思路
燃烧效果可以通过渲染4个区域得到，分别为灰烬区（Ash）、焦黑区（Burned）、燃烧区（Burning）与正常区，通过控制距离函数返回值决定，为求真实，加上了噪音对距离扰动，除此之外，由产热而出现的上升气流会使得燃烧物向上飘动，利用顶点动画实现

### 灰烬区
利用clip函数在片元着色器中实现
```c
//对于距离值大于_AshRate * _Degree * (1 + _BurningRate)，即灰烬区域在总燃烧区域中最大允许占比的部分裁剪
clip((distance + (noise - 0.5) - _AshRate * _Degree * (1 + _BurningRate))* _Degree + 0.05);
```
由于加上了噪音扰动，故需要控制零点保证在燃烧程度为0或很小时不出现灰烬

### 焦黑区
在焦黑区中，需要用物体的焦黑贴图与原贴图混合，实现焦黑的渐变效果，焦黑贴图本身是由原贴图在ps中去色与模糊得到的，为了更贴近真实，可以加上根据噪音贴图随机生成的火星效果
```c
//计算混合因子,利用适当缩小的noise控制边缘渐变
//blendvalue为distance + noise * _BurningRate在Buring区域的位置，柔和插值截断到0-1
float blendvalue = smoothstep(_Degree * (1 - _BurningRate), _Degree * (1 + _BurningRate), 
                            distance + noise * _BurningRate);
//对于blendvalue值小于0的片元，判断为焦黑区，完全用焦黑贴图渲染
//大于1的片元为正常区，为0-1的片元则为燃烧区
col.rgb = lerp(colash + spark, col, blendvalue);
```

### 燃烧区
渲染燃烧区实际上就是要基于blendvalue找到一个火焰遮罩，实际上可以抽象为一个自变量为blendvalue的函数，该函数在自变量属于[0-1]时要满足以下性质：
* 当blendvalue等于0或1时，函数值为0（在完全焦黑的部分与正常部分不出现火焰）
* 在[0-1]内存在一个且只有一个极大值（对应火焰最旺盛的点，这个极大值应该是1，但是由于拟合的有点次数有点高，求解极大值计算量会较大，所以补上了一个经验系数10）
* 在[0-1]内最小值小于0（不希望全为火焰）<br>
在![一个挺好用的绘图网站](https://www.geogebra.org/graphing)拟合了一个满足上述条件的函数![](/Burning/Img/Function.png)，其函数图如下：<br>
![](/Burning/Img/FunctionImg.png)


## 效果示意图
![](/Burning/Img/Burning.gif)<br><br>
也可以通过修改距离函数实现以下效果
![](/Burning/Img/CircleBurning.gif)<br><br>

## 参考
[1] ![利用噪音图制作一个纸张燃烧的效果](https://zhuanlan.zhihu.com/p/115635335)