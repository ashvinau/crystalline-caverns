using Godot;
using System;
using System.Collections.Generic;

public partial class PerlinGraph : Node
{	
private int[,] perlinMatrix;
private Color[,] graphMatrix;
int width, height;

public void CPerlinGraph(int width, int height, int randSeed, double depth, double scale, int octaves, 
double persistence)
{
	List<List<int>> colorRanges = new List<List<int>>	
	{
	new List<int> {0,31,0,0,0,255},
	new List<int> {32,63,64,64,64,255},
	new List<int> {64,95,96,96,96,255},
	new List<int> {96,127,128,128,128,255},
	new List<int> {128,159,160,160,160,255},
	new List<int> {160,191,192,192,192,255},
	new List<int> {192,223,224,224,224,255},
	new List<int> {224,255,255,255,255,255}
	};	
	
	this.width = width;
	this.height = height;
	PerlinNoise graphNoise = new PerlinNoise(4, 256, 2, randSeed);
	perlinMatrix = new int[width,height];	
	graphMatrix = new Color[width,height];	
	
	for (int y = 0; y < height; y++) {
		for (int x = 0; x < width; x++) {
			double px = intToDouble(x);
			double py = intToDouble(y);
			
			double perlinVal = graphNoise.OctavePerlinHalf(px * scale, py * scale, depth * scale, octaves, persistence);
			int matrixVal = doubleToInt(perlinVal);	
			perlinMatrix[x,y] = matrixVal;	
			
			// Clamps assign graph matrix
			
			foreach (List<int> curRange in colorRanges) {
				if (matrixVal > curRange[0] && matrixVal < curRange[1]) {
					graphMatrix[x,y] = new Color(curRange[2], curRange[3], curRange[4], curRange[5]);
				}
			}			
		}
	}	
}

public double intToDouble(int value) {
	return (double) value / 255;
}

private int doubleToInt(double value) {
	return (int) Math.Round(value * 255);
}

public int[] getPerlinMatrix() {	
	int[] flatPerlinMatrix = new int[width * height];
	int curIndex = 0;
	
	for (int y = 0; y < height; y++) {
		for (int x = 0; x < width; x++) {
			flatPerlinMatrix[curIndex] = perlinMatrix[x,y];
			curIndex++;
		}
	}
	return flatPerlinMatrix;
}

public Color[] getGraphMatrix() {
	return new Color[] {};
	//return graphMatrix;
}

// Called when the node enters the scene tree for the first time.
public override void _Ready()
{
}

// Called every frame. 'delta' is the elapsed time since the previous frame.
public override void _Process(double delta)
{
}	


// End of PerlinGraph
}
