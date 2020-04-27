using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Raymarcher : MonoBehaviour
{
    public Material RaymarchMaterial;

    public int Steps = 100;
    public float MaxDepth = 5f;
    public float MinDist = 0.0001f;

    void Update()
    {
        RaymarchMaterial.SetInt("_Steps", Steps);
        RaymarchMaterial.SetFloat("_MaxDepth", MaxDepth);
        RaymarchMaterial.SetFloat("_MinDist", MinDist);
        RaymarchMaterial.SetMatrix("_CameraToWorldMatrix", Camera.main.cameraToWorldMatrix);
        Matrix4x4 m = GL.GetGPUProjectionMatrix(Camera.main.projectionMatrix, true).inverse;
        m[1, 1] *= -1;
        RaymarchMaterial.SetMatrix("_InverseProjectionMatrix",m);
    }
}
