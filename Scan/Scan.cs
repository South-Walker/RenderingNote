using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Scan : MonoBehaviour
{
    public Shader postshader;
    public Camera cam;
    private Material postmat;
    public float radius;
    public float width = 5;
    public RenderTexture rt;
    public Vector3 centerpos = new Vector3(0, 0, 0);
    public float fade = 5;
    private float totaltime = 0;
    // Start is called before the first frame update
    void Start()
    {
        cam.depthTextureMode |= DepthTextureMode.Depth;
        postmat = new Material(postshader);
        rt = new RenderTexture(Screen.width, Screen.height, 16);
    }

    // Update is called once per frame
    void Update()
    {
        totaltime += Time.deltaTime;
    }
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Matrix4x4 frustumCorners = Matrix4x4.identity;

        float fovWHalf = cam.fieldOfView * 0.5f;

        Vector3 toRight = cam.transform.right * cam.nearClipPlane * Mathf.Tan(fovWHalf * Mathf.Deg2Rad) * cam.aspect;
        Vector3 toTop = cam.transform.up * cam.nearClipPlane * Mathf.Tan(fovWHalf * Mathf.Deg2Rad);

        Vector3 topLeft = (cam.transform.forward * cam.nearClipPlane - toRight + toTop);
        float camScale = topLeft.magnitude * cam.farClipPlane / cam.nearClipPlane;

        topLeft.Normalize();
        topLeft *= camScale;

        Vector3 topRight = (cam.transform.forward * cam.nearClipPlane + toRight + toTop);
        topRight.Normalize();
        topRight *= camScale;

        Vector3 bottomRight = (cam.transform.forward * cam.nearClipPlane + toRight - toTop);
        bottomRight.Normalize();
        bottomRight *= camScale;

        Vector3 bottomLeft = (cam.transform.forward * cam.nearClipPlane - toRight - toTop);
        bottomLeft.Normalize();
        bottomLeft *= camScale;

        frustumCorners.SetRow(0, topLeft);
        frustumCorners.SetRow(1, topRight);
        frustumCorners.SetRow(2, bottomRight);
        frustumCorners.SetRow(3, bottomLeft);
        postmat.SetMatrix("_FrustumCorners", frustumCorners);
        postmat.SetVector("_CentPos", centerpos);
        postmat.SetFloat("_Radius", radius);
        postmat.SetFloat("_Width", width);
        postmat.SetFloat("_Fade", fade);
        CustomGraphicsBlit(source, rt, postmat);

        //postmat.SetTexture("_MainTex", source);
        postmat.SetTexture("_MaskTex", rt);
        Graphics.Blit(source, destination, postmat, 1);
    }
    private static void CustomGraphicsBlit(RenderTexture source, RenderTexture dest, Material fxMaterial)
    {
        RenderTexture.active = dest;
        GL.PushMatrix();
        GL.LoadOrtho();

        fxMaterial.SetPass(0);

        GL.Begin(GL.QUADS);

        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f); // BL

        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f); // BR

        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f); // TR

        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f); // TL

        GL.End();
        GL.PopMatrix();
    }
}
