using Godot;
using System.Collections.Generic;

public partial class PerlinNoise : Node
{
	private const int DefaultRandSeed = 12345;
	private readonly int repeat;
	private readonly int[] p;

	private static readonly int[] Permutation =
	{
		// Permutation array as defined by Ken Perlin.
		151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7,
		225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6,
		148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219, 203, 117, 35,
		11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20, 125, 136, 171,
		168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231,
		83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245,
		40, 244, 102, 143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132,
		187, 208, 89, 18, 169, 200, 196, 135, 130, 116, 188, 159, 86, 164,
		100, 109, 198, 173, 186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202,
		38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58,
		17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154,
		163, 70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19,
		98, 108, 110, 79, 113, 224, 232, 178, 185, 112, 104, 218, 246, 97,
		228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162, 241, 81,
		51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181, 199, 106,
		157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236,
		205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215,
		61, 156, 180
	};

	public PerlinNoise() : this(-1, 256, 2, DefaultRandSeed) { }

	public PerlinNoise(int repeat, int periodSize, int periodNum, int randSeed)
	{
		p = new int[periodSize * periodNum];
		List<int> randPerm = PermutationGen(periodSize, periodNum, randSeed);
		this.repeat = repeat;
		for (int x = 0; x < (periodSize * periodNum); x++)
		{
			p[x] = randPerm[x % periodSize];
		}
	}

	public static List<int> PermutationGen(int size, int periods, int rSeed)
	{
		List<int> unRandValues = new List<int>();
		List<int> randValues = new List<int>();
		System.Random indexGen = new System.Random(rSeed);

		for (int p = 1; p <= periods; p++)
		{
			for (int j = 0; j < size; j++)
			{
				unRandValues.Add(j);
			}
		}

		int numPerms = unRandValues.Count;
		for (int t = 0; t < numPerms; t++)
		{
			int curIndex = indexGen.Next(unRandValues.Count);
			randValues.Add(unRandValues[curIndex]);
			unRandValues.RemoveAt(curIndex);
		}

		return randValues;
	}

	public double OctavePerlin(double x, double y, double z, int octaves, double persistence)
	{
	double total = 0;
	double frequency = 1;
	double amplitude = 1;
	double maxValue = 0;  // Used to normalize result to 0.0 - 1.0

	for (int i = 0; i < octaves; i++)
	{
		total += Perlin(x * frequency, y * frequency, z * frequency) * amplitude;

		maxValue += amplitude;

		amplitude *= persistence;
		frequency *= 2;
	}

	return total / maxValue;
}

public double Perlin(double x, double y, double z)
{
	if (repeat > 0)
	{
		x = x % repeat;
		y = y % repeat;
		z = z % repeat;
	}

	int xi = (int)x & 255;
	int yi = (int)y & 255;
	int zi = (int)z & 255;
	
	int aaa = p[p[p[xi] + yi] + zi];
	int aba = p[p[p[xi] + Inc(yi)] + zi];
	int aab = p[p[p[xi] + yi] + Inc(zi)];
	int abb = p[p[p[xi] + Inc(yi)] + Inc(zi)];
	int baa = p[p[p[Inc(xi)] + yi] + zi];
	int bba = p[p[p[Inc(xi)] + Inc(yi)] + zi];
	int bab = p[p[p[Inc(xi)] + yi] + Inc(zi)];
	int bbb = p[p[p[Inc(xi)] + Inc(yi)] + Inc(zi)];

	double xf = x - (int)x;
	double yf = y - (int)y;
	double zf = z - (int)z;
	double u = Fade(xf);
	double v = Fade(yf);
	double w = Fade(zf);

	double x1, x2, y1, y2;

	x1 = Lerp(Grad(aaa, xf, yf, zf), Grad(baa, xf - 1, yf, zf), u);
	x2 = Lerp(Grad(aba, xf, yf - 1, zf), Grad(bba, xf - 1, yf - 1, zf), u);
	y1 = Lerp(x1, x2, v);

	x1 = Lerp(Grad(aab, xf, yf, zf - 1), Grad(bab, xf - 1, yf, zf - 1), u);
	x2 = Lerp(Grad(abb, xf, yf - 1, zf - 1), Grad(bbb, xf - 1, yf - 1, zf - 1), u);
	y2 = Lerp(x1, x2, v);

	return Lerp(y1, y2, w);
}

public double OctavePerlinHalf(double x, double y, double z, int octaves, double persistence)
{
	double total = 0;
	double frequency = 1;
	double amplitude = 1;
	double maxValue = 0;  // Used to normalize result to 0.0 - 1.0

	for (int i = 0; i < octaves; i++)
	{
		total += PerlinHalf(x * frequency, y * frequency, z * frequency) * amplitude;

		maxValue += amplitude;

		amplitude *= persistence;
		frequency *= 2;
	}

	return total / maxValue;
}

public double PerlinHalf(double x, double y, double z)
{
	if (repeat > 0)
	{
		x = x % repeat;
		y = y % repeat;
		z = z % repeat;
	}

	int xi = (int)x & 255;
	int yi = (int)y & 255;
	int zi = (int)z & 255;
	
	int aaa = p[p[p[xi] + yi] + zi];
	int aba = p[p[p[xi] + Inc(yi)] + zi];
	int aab = p[p[p[xi] + yi] + Inc(zi)];
	int abb = p[p[p[xi] + Inc(yi)] + Inc(zi)];
	int baa = p[p[p[Inc(xi)] + yi] + zi];
	int bba = p[p[p[Inc(xi)] + Inc(yi)] + zi];
	int bab = p[p[p[Inc(xi)] + yi] + Inc(zi)];
	int bbb = p[p[p[Inc(xi)] + Inc(yi)] + Inc(zi)];

	double xf = x - (int)x;
	double yf = y - (int)y;
	double zf = z - (int)z;
	double u = Fade(xf);
	double v = Fade(yf);
	double w = Fade(zf);

	double x1, x2, y1, y2;

	x1 = Lerp(Grad(aaa, xf, yf, zf), Grad(baa, xf - 1, yf, zf), u);
	x2 = Lerp(Grad(aba, xf, yf - 1, zf), Grad(bba, xf - 1, yf - 1, zf), u);
	y1 = Lerp(x1, x2, v);

	x1 = Lerp(Grad(aab, xf, yf, zf - 1), Grad(bab, xf - 1, yf, zf - 1), u);
	x2 = Lerp(Grad(abb, xf, yf - 1, zf - 1), Grad(bbb, xf - 1, yf - 1, zf - 1), u);
	y2 = Lerp(x1, x2, v);

	return (Lerp(y1, y2, w) + 1) / 2;
}

public int Inc(int num)
{
	num++;
	if (repeat > 0)
	{
		num %= repeat;
	}
	return num;
}

public static double Grad(int hash, double x, double y, double z)
{
	switch (hash & 0xF)
	{
		case 0x0: return x + y;
		case 0x1: return -x + y;
		case 0x2: return x - y;
		case 0x3: return -x - y;
		case 0x4: return x + z;
		case 0x5: return -x + z;
		case 0x6: return x - z;
		case 0x7: return -x - z;
		case 0x8: return y + z;
		case 0x9: return -y + z;
		case 0xA: return y - z;
		case 0xB: return -y - z;
		case 0xC: return y + x;
		case 0xD: return -y + z;
		case 0xE: return y - x;
		case 0xF: return -y - z;
		default: return 0;  // Never happens
	}
}

public static double Fade(double t)
{
	return t * t * t * (t * (t * 6 - 15) + 10);
}

public static double Lerp(double a, double b, double x)
{
	return a + x * (b - a);
}


//end of PerlinNoise class
}
