import express from 'express';
import pkg from 'agora-access-token';
const { RtcTokenBuilder, RtcRole } = pkg;

const router = express.Router();

const appId = 'a4071bedee5f48ea91a1bed0a3bb7486';
const appCertificate = 'a6f0c1accdab4aca9ca9a4c7d341d2e3';

router.post('/token', async (req, res) => {
  try {
    const { channelName, uid } = req.body;
    
    if (!channelName) {
      return res.status(400).json({ error: 'Channel name is required' });
    }

    const expirationTimeInSeconds = 3600;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      uid || 0,
      RtcRole.PUBLISHER,
      privilegeExpiredTs
    );

    console.log('Token generated for channel:', channelName);
    res.json({ token });
    
  } catch (error) {
    console.error('Token generation error:', error);
    res.status(500).json({ error: 'Failed to generate token' });
  }
});

export default router;
