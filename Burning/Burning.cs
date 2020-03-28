using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Burning : MonoBehaviour
{
    public Material mat;
    public float speed;
    float degree;
    public float max;
    public bool pause;
    // Start is called before the first frame update
    void Start()
    {
        degree = 0;
    }

    // Update is called once per frame
    void Update()
    {
        if (pause)
        {
            return;
        }
        if (degree < max)
            degree += speed;
        else
            degree = 0;
        mat.SetFloat("_Degree", degree);
    }
}
