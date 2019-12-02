using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class SeeThrough : MonoBehaviour
{
    private Renderer[] Renderers;
    private CommandBuffer cbGetOutLand;
    private CommandBuffer cbGetNormal;
    private CommandBuffer cbGetSolidColor;
    public Shader Shader;
    public Color Color;
    public GameObject SeeThroughObj;
    public RenderTexture rtOutland;
    public RenderTexture rtNormal;
    public RenderTexture rtSolidColor;
    public RenderTexture rtBlur;
    public RenderTexture rtTemp;
    public Texture2D Bump;
    [Range(0, 10)] 
    public float BlurSize;
    public float Sensitivity;
    public float Threshold;
    [Range(0, 1)]
    public float EffWeight;
    //pass 0 切线空间法线到屏幕空间法线 pass 1边缘检测 pass 2叠加效果
    //pass 3 纯色 pass 4,5 高斯模糊
    private Material Mat;

    private void Awake()
    {
        cbGetOutLand = new CommandBuffer();
        cbGetOutLand.name = "[See-Through: OutLand]";
        cbGetNormal = new CommandBuffer();
        cbGetNormal.name = "[See-Through: Normal]";
        cbGetSolidColor = new CommandBuffer();
        cbGetSolidColor.name = "[See-Through: SoliColor]";
        rtOutland = new RenderTexture(Screen.width, Screen.height,0);
        rtNormal = new RenderTexture(Screen.width, Screen.height, 0);
        rtSolidColor = new RenderTexture(Screen.width, Screen.height, 0);
        rtBlur = new RenderTexture(Screen.width, Screen.height, 0);
        rtTemp = new RenderTexture(Screen.width, Screen.height, 0);
    }
    // Start is called before the first frame update
    void Start()
    {
        Renderers = SeeThroughObj.GetComponentsInChildren<Renderer>();
        Mat = new Material(Shader);
        Mat.SetColor("_Color", Color.red);
        cbGetOutLand.SetRenderTarget(rtOutland);
        cbGetOutLand.ClearRenderTarget(true, true, Color.black);
        cbGetNormal.SetRenderTarget(rtNormal);
        cbGetNormal.ClearRenderTarget(true, true, Color.black);
        cbGetSolidColor.SetRenderTarget(rtSolidColor);
        cbGetSolidColor.ClearRenderTarget(true, true, Color.black);
        for (int i = 0; i < Renderers.Length; i++)
        {
            cbGetOutLand.DrawRenderer(Renderers[i], Mat, 0, 1);
            cbGetNormal.DrawRenderer(Renderers[i], Mat, 0, 0);
            cbGetSolidColor.DrawRenderer(Renderers[i], Mat, 0, 3);
        }
    }

    // Update is called once per frame
    void Update()
    {
        Mat.SetColor("_Color", Color);
        Mat.SetTexture("_BumpTex", Bump);
        Mat.SetTexture("_NormalTex", rtNormal);
        Mat.SetFloat("_Sensitivity", Sensitivity);
        Mat.SetFloat("_Threshold", Threshold);
        Mat.SetFloat("_EffWeight", EffWeight);
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.ExecuteCommandBuffer(cbGetNormal);
        Graphics.ExecuteCommandBuffer(cbGetOutLand);
        Graphics.ExecuteCommandBuffer(cbGetSolidColor);
        Mat.SetFloat("_BlurSize", BlurSize);
        Mat.SetTexture("_SolidColorTex", rtSolidColor);
        Graphics.Blit(rtSolidColor, rtTemp, Mat, 4);
        Mat.SetTexture("_SolidColorTex", rtTemp);
        Graphics.Blit(rtTemp, rtBlur, Mat, 5);
        Mat.SetTexture("_SolidColorTex", rtBlur);
        Graphics.Blit(rtBlur, rtTemp, Mat, 4);
        Mat.SetTexture("_SolidColorTex", rtTemp);
        Graphics.Blit(rtTemp, rtBlur, Mat, 5);
        Mat.SetTexture("_SolidColorTex", rtBlur);
        Graphics.Blit(rtBlur, rtTemp, Mat, 4);
        Mat.SetTexture("_SolidColorTex", rtTemp);
        Graphics.Blit(rtTemp, rtBlur, Mat, 5);
        Mat.SetTexture("_SolidColorTex", rtBlur);
        
        Mat.SetTexture("_MainTex", source);
        Mat.SetTexture("_MaskTex", rtOutland);
        Mat.SetTexture("_SolidColorTex", rtSolidColor);
        Mat.SetTexture("_BlurTex", rtBlur);
        Graphics.Blit(source, destination, Mat, 2);
    }
}