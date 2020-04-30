using System.Collections;
using System.Collections.Generic;
using UnityEngine;
public class Grass
{
    const int CtrlPointNum = 4;
    GrassControlPoint[] ControlPoints = new GrassControlPoint[CtrlPointNum];
    static List<Grass> Grasses = new List<Grass>();
    public static void CreatToy()
    {
        Vector3 v0 = new Vector3(0, 0, 0);
        Vector3 v1 = new Vector3(2, 4, 0);
        Vector3 v2 = new Vector3(4, 8, 0);
        Vector3 v3 = new Vector3(8, 7, 0);

        Vector3 bottomEw = new Vector3(0, 0, 0.5f);
        Vector3 Ew = bottomEw;
        Grass g = new Grass();

        g.ControlPoints[0] = new GrassControlPoint(v0, Ew);
        Ew = bottomEw * (CtrlPointNum - 1.0f) / CtrlPointNum;
        g.ControlPoints[1] = new GrassControlPoint(v1, Ew);
        Ew = bottomEw * (CtrlPointNum - 2.0f) / CtrlPointNum;
        g.ControlPoints[2] = new GrassControlPoint(v2, Ew);
        Ew = bottomEw * (CtrlPointNum - 3.0f) / CtrlPointNum;
        g.ControlPoints[3] = new GrassControlPoint(v3, Ew);
            
        Grasses.Add(g);

    }
    //这个生成算法的问题在于生成的控制点y值永远增大，实际上有可能弯曲
    //试试看抖动取样？
    public static void CreatN(uint n, float Height, float Width, float Twist)
    {
        Vector3 up = new Vector3(0, 1, 0);
        Vector3 right = new Vector3(0, 0, 1);
        Vector3 Ee, Ew, En;
        Vector3 pre, next;
        
        for (int i = 0; i < n; i++)
        {
            Grass g = new Grass();
            float sintheta = Random.Range(-1.0f, 1.0f);
            float costheta = Mathf.Sqrt(1 - sintheta * sintheta);
            Vector3 ButtomEw = Width * new Vector3(
                Vector3.Dot(new Vector3(costheta, 0, sintheta), right),
                Vector3.Dot(new Vector3(0, 1, 0), right),
                Vector3.Dot(new Vector3(-sintheta, 0, costheta), right));
            pre = new Vector3(Random.Range(-50.0f, 50.0f), 0, Random.Range(-50.0f, 50.0f));
            for (int j = 0; j < CtrlPointNum; j++)
            {
                next = pre + up * (j + 1) * Height;
                next.x += Random.Range(-1.0f, 1.0f) * Twist;
                next.z += Random.Range(-1.0f, 1.0f) * Twist;
                //简单插值，具体计算在shader中
                Ew = ButtomEw * (CtrlPointNum - (float)j) / CtrlPointNum;
                g.ControlPoints[j] = new GrassControlPoint(pre, Ew);
                pre = next;
            }
            Grasses.Add(g);
        }
    }
    public static Mesh CreatMesh()
    {
        Vector3[] vertex = new Vector3[CtrlPointNum * Grasses.Count];
        Vector3[] ew = new Vector3[CtrlPointNum * Grasses.Count];
        int[] quad = new int[CtrlPointNum * Grasses.Count];
        
        int index = 0;
        foreach (var g in Grasses)
        {
            for (int i = 0; i < CtrlPointNum; i++)
            {
                quad[index] = index;
                vertex[index] = g.ControlPoints[i].Position;
                ew[index] = g.ControlPoints[i].Ew;
                index++;
            }
        }
        Mesh m = new Mesh();
        m.vertices = vertex;
        m.normals = ew;
        m.SetIndices(quad, MeshTopology.Quads, 0);
        return m;
    }
}
public class GrassControlPoint
{
    public Vector3 Position;
    public Vector3 Ew;
    public GrassControlPoint(Vector3 Pos, Vector3 ew)
    {
        Position = Pos;
        Ew = ew;
    }
}
public class GrassBehaviour : MonoBehaviour
{
    public Material mat;
    public float Width = 0.2f;
    public float Height = 0.3f;
    public float Twist = 1;
    public Vector3 Wind = Vector3.right;
    GameObject Grasses;
    // Start is called before the first frame update
    void Start()
    {
        Random.InitState(97);
        Grasses = new GameObject("glass");
        Grasses.AddComponent<MeshFilter>();
        var renderer = Grasses.AddComponent<MeshRenderer>();
        Grass.CreatN(30000, Height, Width, Twist);
        //Grass.CreatToy();
        Mesh m = Grass.CreatMesh();
        Grasses.GetComponent<MeshFilter>().mesh = m;
        mat.SetVector("_Wind", Wind);
        renderer.material = mat;
    }


    // Update is called once per frame
    void Update()
    {
        mat.SetVector("_Wind", Wind);
    }
}
