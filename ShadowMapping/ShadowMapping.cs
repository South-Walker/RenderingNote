using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class ShadowMapping : MonoBehaviour
{
    private Camera CamLight;
    public Shader Getz;
    public RenderTexture LightDepth;
    void Start()
    {
        LightDepth = new RenderTexture(2048, 2048, 0, RenderTextureFormat.ARGB64);
        CamLight = new GameObject().AddComponent<Camera>();
        CamLight.name = "DirectionalLight";
        CamLight.clearFlags = CameraClearFlags.SolidColor;
        CamLight.backgroundColor = Color.black;
        CamLight.orthographic = true;
        CamLight.orthographicSize = 40;
        CamLight.transform.position = transform.position;
        CamLight.transform.rotation = transform.rotation;
        CamLight.transform.eulerAngles += new Vector3(0, 45, 0);
        CamLight.nearClipPlane = 0;
        CamLight.farClipPlane = 250;

        CamLight.targetTexture = LightDepth;
        
        CamLight.SetReplacementShader(Getz, "RenderType");
    }
    private void OnPreRender()
    {
        Proj();
    }
    void Proj()
    {
        Matrix4x4 viewM = CamLight.worldToCameraMatrix;
        Matrix4x4 projM = GL.GetGPUProjectionMatrix(CamLight.projectionMatrix, false);
        Matrix4x4 vp = projM * viewM;
        Shader.SetGlobalMatrix("_LIGHT_MATRIX_MVP", vp);
        Shader.SetGlobalTexture("_LightDepth", LightDepth);
    }
}
