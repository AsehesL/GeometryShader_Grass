using System.Collections;
using System.Collections.Generic;
using UnityEngine;

/// <summary>
/// 草生成器：草使用运行时根据贴图生成，这里仅用于测试渲染效果
/// </summary>
public class GrassGenerator : MonoBehaviour
{
    /// <summary>
    /// 草的贴图权重：草贴图上每个草的出现几率
    /// </summary>
    public List<float> grassTextureWeights;
    /// <summary>
    /// 草数量
    /// </summary>
    public int grassCount;
    public Material grassMaterial;
    /// <summary>
    /// 草贴图
    /// </summary>
    public Texture2D grassTexture;

    #region 草场区域设置参数：Demo中只按矩形区域生成，仅用于测试渲染效果
    /// <summary>
    /// 草场区域宽度
    /// </summary>
    public float grassWidth;
    /// <summary>
    /// 草场区域长度
    /// </summary>
    public float grassLength;
    #endregion

    #region 草场生成参数：Demo中直接根据贴图动态生成草，仅用于测试渲染效果
    public Texture2D mask;
    /// <summary>
    /// 方向贴图
    /// </summary>
    public Texture2D dirTex;
    /// <summary>
    /// 大小贴图
    /// </summary>
    public Texture2D size;
    /// <summary>
    /// 初始大小
    /// </summary>
    public float sizeBegin;
    /// <summary>
    /// 方向偏移量
    /// </summary>
    public float dirOffset;
    #endregion

    private Mesh m_Mesh;
    private MeshRenderer m_MeshRenderer;
    private MeshFilter m_MeshFilter;

	void Start ()
	{
	    m_Mesh = new Mesh();

	    List<Vector3> vlist = new List<Vector3>();
	    List<Vector2> ulist = new List<Vector2>();
	    List<Vector2> u2list = new List<Vector2>();
	    List<int> ilist = new List<int>();

        //根据配置的草权重参数数量确定草贴图划分数量
	    float uw = grassTextureWeights.Count > 0 ? 1.0f/grassTextureWeights.Count : 1.0f;

        //计算权重和
	    float totalPriority = 0;
	    for (var i = 0; i < grassTextureWeights.Count; i++)
	    {
	        totalPriority += grassTextureWeights[i];
	    }

	    for (int i = 0; i < grassCount; i++)
	    {
	        float x = Random.Range(0.0f, 1.0f);//生成随机坐标
            float y = Random.Range(0.0f, 1.0f);
	        int pixX = (int) (mask.width-1-x*mask.width);
            int pixY = (int)(mask.height-1- y * mask.height);
	        float maskV = mask.GetPixel(pixX, pixY).r;//计算蒙版值
	        float s = sizeBegin + (1.0f - sizeBegin)*size.GetPixel(pixX, pixY).r;
	        Color dir = dirTex.GetPixel(pixX, pixY);
            float randPriority = Random.Range(0.0f, 1.0f);
	        if (randPriority < maskV) //生成随机值与蒙版值比较
	        {
	            Vector3 p = new Vector3(-grassWidth*0.5f + grassWidth*x, s, -grassLength*0.5f + grassLength*y);
	            Vector2 u = new Vector2((dir.r*2-1)*dirOffset, (dir.g*2-1)*dirOffset);
	            float rd = Random.Range(0.0f, totalPriority);
	            Vector2 u2 = new Vector2(0, uw);

	            float pri = 0.0f;
	            for (int j = 0; j < grassTextureWeights.Count; j++)
	            {
	                if (rd < pri + grassTextureWeights[j])
	                {
                        u2.x = j * uw;
                        u2.y = (j + 1) * uw;
	                    break;
	                }
                    pri += grassTextureWeights[j];
	            }

	            ilist.Add(vlist.Count);
                vlist.Add(p);
	            ulist.Add(u);
	            u2list.Add(u2);
	        }
        }
	    m_Mesh.SetVertices(vlist);
	    m_Mesh.SetUVs(0, ulist);
	    m_Mesh.SetUVs(1, u2list);
	    m_Mesh.SetIndices(ilist.ToArray(), MeshTopology.Points, 0); //生成草的点云，实际渲染使用点渲染，并在GS中生成公告板面片

	    m_MeshFilter = gameObject.AddComponent<MeshFilter>();
	    m_MeshRenderer = gameObject.AddComponent<MeshRenderer>();

	    m_MeshFilter.sharedMesh = m_Mesh;
	    m_MeshRenderer.sharedMaterial = grassMaterial;
	    grassMaterial.SetTexture("_MainTex", grassTexture);
	}

    void OnDestroy()
    {
        if (m_Mesh)
            Destroy(m_Mesh);
        m_Mesh = null;
    }

    void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.green;

        Vector3 p0 = new Vector3(-grassWidth*0.5f, 0, -grassLength*0.5f);
        Vector3 p1 = new Vector3(-grassWidth * 0.5f, 0, grassLength * 0.5f);
        Vector3 p2 = new Vector3(grassWidth * 0.5f, 0, grassLength * 0.5f);
        Vector3 p3 = new Vector3(grassWidth * 0.5f, 0, -grassLength * 0.5f);

        Gizmos.DrawLine(p0, p1);
        Gizmos.DrawLine(p1, p2);
        Gizmos.DrawLine(p2, p3);
        Gizmos.DrawLine(p3, p0);
    }
}
