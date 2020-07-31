using System;

namespace DCManagement
{
	[Flags]
	public enum FileSystemPermission : uint
	{
		ListDirectory = 1,
		ReadData = 1,
		WriteData = 2,
		CreateFiles = 2,
		CreateDirectories = 4,
		AppendData = 4,
		ReadExtendedAttributes = 8,
		WriteExtendedAttributes = 16,
		Traverse = 32,
		ExecuteFile = 32,
		DeleteSubdirectoriesAndFiles = 64,
		ReadAttributes = 128,
		WriteAttributes = 256,
		Write = 278,
		Delete = 65536,
		ReadPermissions = 131072,
		Read = 131209,
		ReadAndExecute = 131241,
		Modify = 197055,
		ChangePermissions = 262144,
		TakeOwnership = 524288,
		Synchronize = 1048576,
		FullControl = 2032127,
		GenericAll = 268435456,
		GenericExecute = 536870912,
		GenericWrite = 1073741824,
		GenericRead = 2147483648
	}
}
