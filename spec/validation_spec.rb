require 'spec_helper'

GOOD_PEM_PUB = <<EOF
-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAObhVj6YOhhSwf7uJ1o1c/oGr5ghfCoY1qvrOBs8R7qqCkX2dJAH3yAw
5txn0fuoabd79tBMKuUEAH+MxRBBtPI+wTLekgp5ag+XsZNClxJL1ZmgdhfJ/hM3
www54nesZvIZvxebXdH5IGk4w5l+dPcpQkvOchhW0G+/64XP8L17AgMBAAE=
-----END RSA PUBLIC KEY-----
EOF

GOOD_PEM_PRIV = <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQDm4VY+mDoYUsH+7idaNXP6Bq+YIXwqGNar6zgbPEe6qgpF9nSQ
B98gMObcZ9H7qGm3e/bQTCrlBAB/jMUQQbTyPsEy3pIKeWoPl7GTQpcSS9WZoHYX
yf4TN8MMOeJ3rGbyGb8Xm13R+SBpOMOZfnT3KUJLznIYVtBvv+uFz/C9ewIDAQAB
AoGAMJzLkvxsZwitziaI5KaSl9dmi4qpYRe/w40QUDO+CqCY7yg4XMc7hMSnJ0s4
3FsWf0q7qhoPgg74p+KU75pWJbEHoYor6LqDuxov4DSx/2SfqmDBIAb9IQ4KWDr2
WU/o2/ivbHJ89FxCCroMzNg+qm8pAHVYQ72E/w/1sSRuQPECQQD4fes0OrE8qlJ0
0UCxiTbotreNY7N/pKPIFqL/+ODcXJIHCyvVAMXw469r9KacrC/t8qKNatWk3mP1
uZzfoAJJAkEA7dsxOJcTqMAncOzbP2cXPkGvzyS06mUoziuZWDc+NAOy4R/V/xHW
+CUleXs06G9c/LoZ+E80MP600YvPtKUBowJAZXXMfnPkgDevGUGDX7n98IECazml
Rd3sfbs4bLmq3m7xtOyLxhnduGDO9I5dJSVtIIPseT+A4iNnvyI9elVz+QJALTBe
mpTBTGctVxv4z4Pje5V5NE6R/JI5fWn1GThtne4x9ulYe7xE7iIIi5rnw10c+nrU
4kMR9Fj/u2vnizdqJwJACb7DY5rKZa/xgzgLtE5jW60zZWvwS9LYUs+1ND6CeiFy
s3EiH2z+zbSO+cnMtCutdRKIHk3wy6tyRKOq0EMafA==
-----END RSA PRIVATE KEY-----
EOF

GOOD_ENCRYPTED_PEM_PRIV = <<EOF
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,61C0BBB816A708D4

SQ/Y+U7z51OL/hx4YnfVPl6uqsOjpSjU2w4NFqB6EyBtMFgOoqW6ryuIi6ycHgWJ
YabUlMPdnexU+1BGqu9P2M9kQejfVddBFmbE09s54dwamk7q6RjaARN0UvHq6Ms9
r5/nqRBrinWtOeU/+7cV5qGp2/HbWC2bHAUCCwBcq+ymEpLOw/dpHpxjuiB5ZOLt
QzcEJ8ePlNDYvPxw4Wjvb5IDjS4MSoJfA5Y2ZXwVSI1d7mhx4Cekx3CkTMWKYIU8
FS6hO39tfPTcxb4os3FYl8D8TlRHv5atrsptKqYE4DKhZhoDA5yFbFJHZlEp+G6H
t+snMyuzEWNWq3wGI/gaglatUMq6airA50qticbw8kvz+67pPh2gkAgMXBHEGgPW
m0xnqaWf+MyQCUfaxjvxAq68Ced+H9ULLYFrzWAIuSh1M+QartuvP1ZOIcDpY83i
RybTJC5MLgGE0COM7oOtPfXO/rvdf6jqTr54HhYwq18aWrqjnacZi0JzNEFRtpNa
5FNbwbQGT4Y8J1rOgbyjrd712oRhfjMAU39w4b6gEIATB4zDnMVkdb/Rde/nB7i4
CqDB9iSEbtQN4Ev5fXpIDrmhbdT/CURpzRvIt68x08qvX8KQwqDbLz39luocApxN
lnTihGiYAiNflMpDvhNL8MSLxYgL5Or2KVF/Ppc+1Qw23BEYDlaRRzc71PWdrVr8
UxEdFtqQnnthO7PabrwmLiPeArIGL4U8wrbXA3GbkbDtClftWMaC9JrzVJvXp1z7
sXZPhdZzSCg3n3ZbAGKYUx/G8AHojLKfAF3BHufnU9qM+6TS/KtTnhrvHSgYPcBn
etI7DWZ/mUnLwnsWfiQ3n5PeeUq/nU+IFJT+Y3r+TfFVCiGPW60XpfLzH1U4otKq
KaEnCQX6S7p1Jinx+FHL9fg1I50E6QUNO+N8XO4ay3Jzumz2yjZeudyt+uy954Hq
RfmDGYImqrkYrzd8d6hNUTBGnUfUTvq2k/orKhvcxtX+tr9WhNshnJcK18SgBRKT
6XLybyioikVSpUGsL95kIhrspryO8v7/M1igWWrLu9fe/jUJLCFzlbGSRYDn+QTp
z7qpbBvxHPgu1fKurZ96nCcigVxQgY5rPwpQvG+mkD6YOhgDvSAjTos7Fagz6nb6
01MufCVvFx+BBZEsol0Ag23RhXeJXvxkcF//hcPseCA/oB9Aqzyu+ml9mgp4v6P+
AgVopgGCfZR31CQ2b9AxdSARFCj2AFE9AdeNy268KSx8wLWAlzUcnGi57eK8WJM3
KTDOwJZDgZkjYyMZATpxOj8w3euAflQjQmyXpN1/Q0BW66Mj9+XzVk2yEpF2S0iE
xKzPcNEzlGMo1xo6mqVE/kIuRSodXuGp5Eoo8ITvpYWcSdtCTSKJNxAUqry/k9bg
9sf3jSmSHzUd92pdM02p8A42HcaPGLmbuFjIfZPK7KoYmIdhJqy7s08CFUlk9XI/
PxdYph5J4WkAbeomPGUTFxEWV1cM2lvW4hotrx8MS50WLVZxxY1p7D+JxN3KeJyc
mytYpg2dxr8UF64NFKuyEmunkDTdYH2Oi7B7mAcw/QlBN+qCARP+tA==
-----END RSA PRIVATE KEY-----
EOF

GOOD_SSH_PUB = <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEApfGJ2lzcKgWq50u4yhZyP7yDjA4\
CF2pV19TUOlXg4a40FCuKi7JIqPCyixmrWYrvRFz+5zY+gHWOHkCfjNaDryUgPs\
BMzk2DZDD8fsrJ5KU7QDAa1RMbixnWsWTDcXGhHxC7jtRV7qKFvribLYEoUfVbW\
ZYQR3Wl9kfc78sF6Z2TZuL2Fb9YJc5f2uDz6+I6oy8LtGci4Y2hKVYxrN5tgvFc\
wkE8JsRaAnjWicfoHRUIBZ/tdT76EMhBEKdO63hO9AZ8phTyZoJyLzykDRaelBU\
YXjG0LQXTq4jiJhKa07kv0XIgNwnz4zB9qtiOHXm6KZZDxy7xnVXOFum+JqcUxQ\
== user@host
EOF

describe RightSupport::Validation do
  def corrupt(key, factor=4)
    d = key.size / 2

    key[0..(d-factor)] + key[d+factor..-1]
  end
  
  context :pem_public_key? do
    it 'recognizes valid keys' do
      RightSupport::Validation.pem_public_key?(GOOD_PEM_PUB).should == true
    end
    it 'recognizes bad keys' do
      RightSupport::Validation.pem_public_key?(corrupt(GOOD_PEM_PUB)).should == false      
      RightSupport::Validation.pem_public_key?(nil).should == false
      RightSupport::Validation.pem_public_key?('').should == false
    end
  end

  context :pem_private_key? do
    it 'recognizes valid keys' do
      RightSupport::Validation.pem_private_key?(GOOD_PEM_PRIV).should == true
    end
    it 'considers encrypted keys to be "bad" (not usable)' do
      RightSupport::Validation.pem_private_key?(GOOD_ENCRYPTED_PEM_PRIV).should == false      
    end
    it 'recognizes bad keys' do
      RightSupport::Validation.pem_private_key?(corrupt(GOOD_PEM_PRIV)).should == false
      RightSupport::Validation.pem_private_key?(corrupt(GOOD_PEM_PRIV, 16)).should == false
      RightSupport::Validation.pem_private_key?(nil).should == false
      RightSupport::Validation.pem_private_key?('').should == false
    end
  end

  context :ssh_public_key? do
    it 'recognizes valid keys' do
      RightSupport::Validation.ssh_public_key?(GOOD_SSH_PUB).should == true
    end
    it 'recognizes bad keys' do
      RightSupport::Validation.ssh_public_key?('ssh-rsa AAAAB3Nhowdybob').should == false
      RightSupport::Validation.ssh_public_key?('ssh-rsa hello there').should == false
      RightSupport::Validation.ssh_public_key?('ssh-rsa one two three! user@host').should == false
      RightSupport::Validation.ssh_public_key?(nil).should == false
      RightSupport::Validation.ssh_public_key?('').should == false      
    end
  end
end