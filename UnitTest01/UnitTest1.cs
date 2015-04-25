using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.IO;
using System.Configuration;
using System.Management;
using System.Management.Automation;

[assembly: log4net.Config.XmlConfigurator(ConfigFile = "UnitTest01.dll.config", Watch = true)]
namespace biz.dfch.CS.PowerShellUnitTestSample
{
    [TestClass]
    public class UnitTest1
    {
        private static TestContext _testContext;
        public TestContext testContext
        {
            get
            {
                return _testContext;
            }
            set
            {
                _testContext = value;
            }
        }

        [AssemblyInitialize]
        public static void Configure(TestContext testContext)
        {
            log4net.Config.XmlConfigurator.Configure();
        }
        [ClassInitialize()]
        public static void classInitialize(TestContext testContext)
        {
            _testContext = testContext;
            Trace.WriteLine("classInitialize: '{0}'", testContext.TestName, "");
        }

        [ClassCleanup()]
        public static void classCleanup()
        {
            Trace.WriteLine("classCleanup");
        }

        [TestInitialize()]
        public void testInitialize()
        {
            Trace.WriteLine("testInitialize");
        }

        [TestCleanup()]
        public void testCleanup()
        {
            Trace.WriteLine("testCleanup");
        }

        [TestMethod]
        public void doNothingReturnsTrue()
        {
            Assert.AreEqual(true, true);
        }
        
        [TestMethod]
        public void doNothingReturnsFalse()
        {
            Assert.AreEqual(false, false);
        }

        [TestMethod]
        public void doAddNumbersReturns7()
        {
            var x = 3;
            var y = 4;
            var testResult = 7;

            PowerShell ps = PowerShell.Create();
            var results = ps.AddScript( String.Format("return {0} + {1}", x, y) )
                .Invoke();
            var result = results[0];
            Assert.AreEqual(testResult, Convert.ToInt32(result.ToString()));
        }

        [TestMethod]
        public void doConvertToJsonReturnsTrue()
        {
            var jsonText = "{\"_number\":42,\"_string\":\"hello, world\"}";

            PowerShell ps = PowerShell.Create();
            var results = ps
                .AddCommand("Import-Module")
                .AddParameter("Name", "Microsoft.PowerShell.Utility")
                .Invoke();

            ps.Commands.Clear();
            results = ps.AddScript("$ht = @{}; $ht._number = 42; $ht._string = 'hello, world'; $ht | ConvertTo-Json -Compress;")
                .Invoke();
            var result = results[0];
            Assert.AreEqual(jsonText, result.ToString());
        }

        [TestMethod]
        public void doConvertFromJsonReturnsTrue()
        {
            var jsonText = "{\"_number\":42,\"_string\":\"hello, world\"}";

            PowerShell ps = PowerShell.Create();
            var results = ps
                .AddCommand("Import-Module")
                .AddParameter("Name", "Microsoft.PowerShell.Utility")
                .Invoke();

            ps.Commands.Clear();
            results = ps.AddScript(String.Format("'{0}' | ConvertFrom-Json;", jsonText))
                .Invoke();
            var result = results[0];
            Assert.AreEqual(42, result.Properties.Match("_number")[0].Value);
            Assert.AreEqual("hello, world", result.Properties.Match("_string")[0].Value);
        }

        [TestMethod]
        public void doConvertToBase64ReturnsTrue()
        {
            var plainText = "tralala";

            PowerShell ps = PowerShell.Create();
            ps.Commands.Clear();
            var results = ps
                .AddCommand("Import-Module")
                .AddParameter("Name", "biz.dfch.PS.System.Utilities")
                .Invoke();
            ps.Commands.Clear();
            results = ps.AddCommand("ConvertTo-Base64")
                .AddParameter("InputObject", plainText)
                .Invoke();
            var result = results[0];
            var encodedText = Base64Encode(plainText);
            Assert.AreEqual(encodedText, result.ToString());
        }

        [TestMethod]
        public void doConvertRandomToBase64ReturnsTrue()
        {
            var plainText = GenerateRandomString(128);

            PowerShell ps = PowerShell.Create();
            ps.Commands.Clear();
            var results = ps
                .AddCommand("Import-Module")
                .AddParameter("Name", "biz.dfch.PS.System.Utilities")
                .Invoke();
            ps.Commands.Clear();
            results = ps.AddCommand("ConvertTo-Base64")
                .AddParameter("InputObject", plainText)
                .Invoke();
            var result = results[0];
            var encodedText = Base64Encode(plainText);
            Assert.AreEqual(encodedText, result.ToString());
        }

        [TestMethod]
        public void doConvertRandomMultiFixToBase64ReturnsTrue()
        {
            PowerShell ps = PowerShell.Create();
            var results = ps
                .AddCommand("Import-Module")
                .AddParameter("Name", "biz.dfch.PS.System.Utilities")
                .Invoke();
            for (UInt32 c = 0; c < 1000; c++)
            {
                var plainText = GenerateRandomString(128);

                ps.Commands.Clear();
                results = ps.AddCommand("ConvertTo-Base64")
                    .AddParameter("InputObject", plainText)
                    .Invoke();
                var result = results[0];
                var encodedText = Base64Encode(plainText);
                Assert.AreEqual(encodedText, result.ToString());
            }
        }

        [TestMethod]
        public void doConvertRandomMultiVarToBase64ReturnsTrue()
        {
            PowerShell ps = PowerShell.Create();
            var results = ps
                .AddCommand("Import-Module")
                .AddParameter("Name", "biz.dfch.PS.System.Utilities")
                .Invoke();
            for (UInt32 c = 0; c < 1000; c++)
            {
                var plainText = GenerateRandomString(c);

                ps.Commands.Clear();
                results = ps.AddCommand("ConvertTo-Base64")
                    .AddParameter("InputObject", plainText)
                    .Invoke();
                var result = results[0];
                var encodedText = Base64Encode(plainText);
                Assert.AreEqual(encodedText, result.ToString());
            }
        }

        [TestMethod]
        public void doConvertFromBase64ReturnsTrue()
        {
            var encodedText = "dHJhbGFsYQ==";

            PowerShell ps = PowerShell.Create();
            ps.Commands.Clear();
            var results = ps
                .AddCommand("Import-Module")
                .AddParameter("Name", "biz.dfch.PS.System.Utilities")
                .Invoke();
            ps.Commands.Clear();
            results = ps.AddCommand("ConvertFrom-Base64")
                .AddParameter("InputObject", encodedText)
                .Invoke();
            Assert.IsNotNull(results);
            Assert.AreEqual(1, results.Count);
            var result = results[0];
            var plainText = Base64Decode(encodedText);
            Assert.AreEqual(plainText, result.ToString());
        }

        [TestMethod]
        public void doConvertRandomFromBase64ReturnsTrue()
        {
            var encodedText = Base64Encode(GenerateRandomString(128));

            PowerShell ps = PowerShell.Create();
            ps.Commands.Clear();
            var results = ps
                .AddCommand("Import-Module")
                .AddParameter("Name", "biz.dfch.PS.System.Utilities")
                .Invoke();
            ps.Commands.Clear();
            results = ps.AddCommand("ConvertFrom-Base64")
                .AddParameter("InputObject", encodedText)
                .Invoke();
            Assert.IsNotNull(results);
            Assert.AreEqual(1, results.Count);
            var result = results[0];
            var plainText = Base64Decode(encodedText);
            Assert.AreEqual(plainText, result.ToString());
        }

        [TestMethod]
        public void doConvertRandomMultiFixFromBase64ReturnsTrue()
        {
            PowerShell ps = PowerShell.Create();
            var results = ps
                .AddCommand("Import-Module")
                .AddParameter("Name", "biz.dfch.PS.System.Utilities")
                .Invoke();
            for (UInt32 c = 0; c < 1000; c++)
            {
                var encodedText = Base64Encode(GenerateRandomString(128));

                ps.Commands.Clear();
                results = ps.AddCommand("ConvertFrom-Base64")
                    .AddParameter("InputObject", encodedText)
                    .Invoke();
                var result = results[0];
                var plainText = Base64Decode(encodedText);
                Assert.AreEqual(plainText, result.ToString());
            }
        }

        [TestMethod]
        public void doConvertRandomMultiVarFromBase64ReturnsTrue()
        {
            PowerShell ps = PowerShell.Create();
            var results = ps
                .AddCommand("Import-Module")
                .AddParameter("Name", "biz.dfch.PS.System.Utilities")
                .Invoke();
            for (UInt32 c = 0; c < 1000; c++)
            {
                var encodedText = Base64Encode(GenerateRandomString(128));

                ps.Commands.Clear();
                results = ps.AddCommand("ConvertFrom-Base64")
                    .AddParameter("InputObject", encodedText)
                    .Invoke();
                var result = results[0];
                var plainText = Base64Decode(encodedText);
                Assert.AreEqual(plainText, result.ToString());
            }
        }

        [TestMethod]
        public void doWriteHostReturnsTrue()
        {
            var fn = String.Format("{0}:{1}.{2}", this.GetType().Namespace, this.GetType().Name, System.Reflection.MethodBase.GetCurrentMethod().Name);
            Trace.WriteLine(fn);

            var msg = "hello, world!";
            PowerShell ps = PowerShell.Create();
            ps.Commands.Clear();
            ps
                .AddScript("function Write-Host($Object) { return $Object; }")
                .Invoke();
            var results = ps
                .AddCommand("Write-Host")
                .AddParameter("Object", msg)
                .Invoke();
            Assert.IsNotNull(results);
            Assert.AreEqual(1, results.Count);
            Assert.AreEqual(msg, results[0]);
        }

        [TestMethod]
        [ExpectedException(typeof(CmdletInvocationException))]
        public void doWriteHostThrowsCmdletInvocationException()
        {
            var fn = String.Format("{0}:{1}.{2}", this.GetType().Namespace, this.GetType().Name, System.Reflection.MethodBase.GetCurrentMethod().Name);
            Trace.WriteLine(fn);

            PowerShell ps = PowerShell.Create();
            ps.Commands.Clear();
            var results = ps
                .AddCommand("Write-Host")
                .AddParameter("Object", "hello, world!")
                .Invoke();
        }

        // This method is not a TestMethod, but can be invoked from PowerShell to run all TestMethods in this class.
        public void Run()
        {
            var fn = String.Format("{0}:{1}.{2}", this.GetType().Namespace, this.GetType().Name, System.Reflection.MethodBase.GetCurrentMethod().Name);
            Trace.WriteLine("{0}: Running tests ...", fn, "");
            Type type = this.GetType();
            var am = type.GetMethods();
            foreach (var m in am)
            {
                var isTestMethod = false;
                var expectedException = String.Empty;
                foreach(var customAttribute in m.CustomAttributes)
                {
                    if (customAttribute.ToString().Equals(String.Format("[Microsoft.VisualStudio.TestTools.UnitTesting.{0}()]", "TestMethodAttribute")))
                    {
                        isTestMethod = true;
                    }
                    if (customAttribute.ToString().StartsWith(String.Format("[Microsoft.VisualStudio.TestTools.UnitTesting.{0}", "ExpectedExceptionAttribute")))
                    {
                        expectedException = customAttribute.ConstructorArguments[0].Value.ToString();
                    }
                }
                if (!isTestMethod || System.Reflection.MethodBase.GetCurrentMethod().Name.Equals(m.Name))
                {
                    continue;
                }
                Trace.WriteLine("Invoking '{0}' ...", m.Name, "");
                try
                {
                    var result = m.Invoke(this, null);
                }
                catch(Exception ex)
                {
                    if(null == ex.InnerException || !ex.InnerException.GetType().FullName.Equals(expectedException))
                    {
                        throw ex;
                    }
                }
                Trace.WriteLine("Invoking '{0}' SUCCEEDED.", m.Name, "");
            }
            Trace.WriteLine("{0}: Running tests COMPLETED.", fn, "");
        }
        private static String GenerateRandomString(UInt32 size)
        {
            Random _rng = new Random();
            const String _chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+*ç%&/()=?`^~¨!$£ü[]{}§°üäöÜÄÖ,;.:-_éáóèàò|¢´";

            char[] buffer = new char[size];
            for (UInt32 i = 0; i < size; i++)
            {
                buffer[i] = _chars[_rng.Next(_chars.Length)];
            }
            return new String(buffer);
        }
        private static String Base64Encode(String plainText)
        {
            var plainTextBytes = System.Text.Encoding.UTF8.GetBytes(plainText);
            return System.Convert.ToBase64String(plainTextBytes);
        }
        private static String Base64Decode(String base64EncodedData)
        {
            var base64EncodedBytes = System.Convert.FromBase64String(base64EncodedData);
            return System.Text.Encoding.UTF8.GetString(base64EncodedBytes);
        }
    }
}

/**
 *
 *
 * Copyright 2015 Ronald Rink, d-fens GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */
