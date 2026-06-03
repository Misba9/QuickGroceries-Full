export interface DeliveryTipSettings {
  enabled: boolean;
  suggestedTips: number[];
  maxTipAmount: number;
}

export const DEFAULT_DELIVERY_TIP_SETTINGS: DeliveryTipSettings = {
  enabled: true,
  suggestedTips: [10, 20, 50, 100],
  maxTipAmount: 500,
};

export const DELIVERY_TIPS_SETTINGS_PATH = "app_settings/delivery_tips";
