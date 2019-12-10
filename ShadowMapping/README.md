# 阴影映射
## 基本思路
通过在光源位置设置摄像机的方法，在光源的模型空间（设置摄像机的投影空间）中保存距离光源最近的体素离光源的距离。在渲染过程中将预备接受阴影的片元转换到光源的模型空间中，与缓存的距离比较大小，距离较远说明光线会优先照射到别的物体，该片元为阴影，距离较近说明光线能够照射到该片元，该片元非阴影
### 获取深度
* 通过在光源位置设置摄像机的方法获取摄像机的MVP矩阵
* 对摄像机对象调用SetReplacementShader方法，设置着色器为获取深度的着色器，此时可以限制replacementTag不着色接受阴影的物体
* 修改targetTexture属性，保存渲染结果
* 深度值用EncodeFloatRGBA编码到四个分量中<br><br>
![](/ShadowMapping/Img/LightDepth.png)<br>
(此处待接受阴影的平面没有被着色，取而代之的是在远处着色了一个大平面作为背景)<br>
### 同一坐标空间内比较深度大小
* 利用光源摄像机的MVP矩阵将预备接受阴影的片元从模型空间转换到光源摄像机的裁剪空间，在同一个空间比较深度大小，vp矩阵可以从光源摄像机的属性中得到
```c#
Matrix4x4 viewM = CamLight.worldToCameraMatrix;
Matrix4x4 projM = GL.GetGPUProjectionMatrix(CamLight.projectionMatrix, false);
Matrix4x4 vp = projM * viewM;
```
* 在着色器中主要是将模型空间坐标转换为世界空间，再乘以vp矩阵得到在光源摄像机投影空间中的坐标与片元离光源距离
* 基于投影坐标在深度纹理图中对应位置采样，并解码得到具光源最近的距离
* 比较上述得到的两个距离，判断是否能直接被光源照射到
## 效果示意图
最终效果如下：<br><br>
![](/ShadowMapping/Img/Eff.png)<br><br>