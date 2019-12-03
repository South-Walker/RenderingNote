# 透视效果
## 基本思路
利用CommandBuffer保存Renderer属性，防止在裁剪中丢失，为了获得更好的效果使用了基于法线的边缘探测与高斯模糊。
### 基于法线的边缘探测
不使用法线的边缘探测一般只能对物体外部轮廓进行描边，很难识别物体内部的轮廓。而基于法线的边缘探测一般是对摄像机法线纹理采样得到的，当物体可能被遮挡时其法线难以直接获得，且待渲染物体本身的法线是经过法线纹理扰动的，并不存储在顶点中。在这里，根据片元对法线纹理的采样，将法线值由切线空间恢复到了世界空间,并保存在纹理里。<br><br>
![](/SeeThrough/SeeThroughNormal.png)<br><br>
在这个基础上进行边缘探测，得到描边的效果<br><br>
![](/SeeThrough/SeeThroughEdge.png)<br><br>
另外，为了附加外部边缘发光的效果，对纯色的渲染结果进行了3次高斯模糊，减去原图得到边缘发光效果<br><br>
![](/SeeThrough/SeeThroughEdgeLight.png)<br><br>

## 效果示意图
将上述效果在source上叠加得到的最终效果如下：<br><br>
![](/SeeThrough/SeeThroughEff.png)<br><br>
