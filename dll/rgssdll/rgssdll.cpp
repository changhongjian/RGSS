
#include "stdafx.h"
#include "rgssdll.h"
#include "Bitmap.h"

RGSSDLL_API inverse(const DWORD object_id, const DWORD color)
{
	Bitmap bmp(object_id);
	for (DWORD &pixel : bmp)
	{
		pixel ^= color;
	}
	return 0;
}
