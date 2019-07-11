using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class VectorRenderObject : MonoBehaviour
{
    public Material material;
	public bool autoAdd;
    public float size = 1.0f;

    private Mesh m_Mesh;

	private List<Vector3> m_PositionList;

	private Vector3 m_Position;

    void Start()
    {
        m_Mesh = new Mesh();
        m_Mesh.vertices = new Vector3[]
        {
            new Vector3(-0.5f, 0.0f, -0.5f), new Vector3(-0.5f, 0.0f, 0.5f),
            new Vector3(0.5f, 0.0f, 0.5f), new Vector3(0.5f, 0.0f, -0.5f)
        };
        m_Mesh.uv = new Vector2[]
        {
            new Vector2(0, 0), new Vector2(0, 1),
            new Vector2(1, 1), new Vector2(1, 0),
        };
        m_Mesh.triangles = new int[] { 0, 1, 2, 0, 2, 3 };

	    m_PositionList = new List<Vector3>();

	    m_Position = transform.position;

    }

	void Update()
	{
		if (autoAdd)
		{
			float dis = Vector3.Distance(transform.position, m_Position);
			if (dis > 0.2f)
			{
				m_Position = transform.position;
				m_PositionList.Add(transform.position);
			}
		}
	}

    void OnDestroy()
    {
        if (m_Mesh)
            Destroy(m_Mesh);
    }

    void OnRenderObject()
    {
        if (Camera.current == Camera.main)
        {
            Matrix4x4 matrix = Matrix4x4.TRS(transform.position, Quaternion.identity, Vector3.one * size);
            VectorRenderer.DrawMesh(m_Mesh, material, matrix);

	        if (autoAdd)
	        {
		        for (int i = 0; i < m_PositionList.Count; i++)
		        {
			        matrix = Matrix4x4.TRS(m_PositionList[i], Quaternion.identity, Vector3.one * size);
			        VectorRenderer.DrawMesh(m_Mesh, material, matrix);
				}
	        }
        }
    }
}
